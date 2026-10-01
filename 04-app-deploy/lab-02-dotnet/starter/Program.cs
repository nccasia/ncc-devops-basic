// Employees API — ASP.NET Core minimal API.
//
// Run locally (dev):
//   set -a; . ./app.env.example; set +a
//   ASPNETCORE_URLS=http://127.0.0.1:5001 dotnet run
//
// Build for deployment:
//   dotnet publish -c Release -o ./publish
using Npgsql;

var builder = WebApplication.CreateBuilder(args);

string Env(string name, string? fallback = null) =>
    Environment.GetEnvironmentVariable(name) ?? fallback
    ?? throw new InvalidOperationException($"Missing environment variable {name}");

var connString = new NpgsqlConnectionStringBuilder
{
    Host = Env("DB_HOST"),
    Port = int.Parse(Env("DB_PORT", "5432")),
    Database = Env("DB_NAME"),
    Username = Env("DB_USER"),
    Password = Env("DB_PASSWORD"),
    Timeout = 5,
}.ConnectionString;

builder.Services.AddSingleton(NpgsqlDataSource.Create(connString));

var app = builder.Build();

app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.MapGet("/api/employees", async (NpgsqlDataSource db, ILogger<Program> logger) =>
{
    try
    {
        await using var cmd = db.CreateCommand(
            "SELECT e.id, e.full_name, e.email, COALESCE(d.name, '') AS department FROM employees e LEFT JOIN departments d ON d.id = e.department_id ORDER BY e.id");
        await using var reader = await cmd.ExecuteReaderAsync();

        var employees = new List<object>();
        while (await reader.ReadAsync())
        {
            employees.Add(new
            {
                id = reader.GetInt32(0),
                full_name = reader.GetString(1),
                email = reader.GetString(2),
                department = reader.GetString(3),
            });
        }
        return Results.Ok(employees);
    }
    catch (NpgsqlException ex)
    {
        logger.LogError(ex, "Database error");
        return Results.Json(new { error = "database unavailable" }, statusCode: 503);
    }
});

app.Run();
