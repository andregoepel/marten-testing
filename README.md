# AndreGoepel.Marten.Testing

Shared Testcontainers/PostgreSQL Marten integration-test fixture for the AndreGoepel .NET ecosystem — one `MartenFixture`, one pinned Postgres digest, instead of every repo carrying its own copy.

## Why

Two sibling repos (`marten-configuration`, `marten-identity`) each carried a near-identical `MartenFixture` + `IntegrationCollection`: same `PostgreSqlContainer` lifecycle, same pinned image digest, same `DocumentStore.For(...)` / `ResetAsync` shape. Keeping the digest in lockstep across repos by hand is exactly the kind of thing that silently drifts. Three more host apps (`finance-app`, `app-foundation`, `andregoepel-dev`) have no integration fixture at all and mock `IDocumentStore`/`IDocumentSession`/`IQuerySession` with NSubstitute instead — `andregoepel-dev` even hand-built a reflection proxy just to simulate a DB outage. This package gives every consumer a real Postgres to test against instead.

## Usage

Reference the package from a test project and use the fixture directly if you don't need any extra store configuration:

```csharp
[CollectionDefinition(Name)]
public sealed class IntegrationCollection : ICollectionFixture<MartenFixture>
{
    public const string Name = "Integration";
}
```

> Define this `IntegrationCollection` yourself in your test project rather than referencing one from this package. xunit collection fixtures are scoped per test assembly, so a collection defined here can't be shared as one physical container across multiple consuming assemblies anyway — each test project pays its own container start-up cost regardless of which assembly declares the `[CollectionDefinition]`. The package does still ship its own `IntegrationCollection` (bound to the base `MartenFixture`) as a working example / copy-paste starting point, not as something to reference across assembly boundaries.

```csharp
[Collection(IntegrationCollection.Name)]
public sealed class MyStoreTests(MartenFixture fixture) : IAsyncLifetime
{
    private CancellationToken Ct => TestContext.Current.CancellationToken;

    public async ValueTask InitializeAsync() => await fixture.ResetAsync(Ct);

    public ValueTask DisposeAsync() => ValueTask.CompletedTask;

    [Fact]
    public async Task SaveAsync_ThenLoadAsync_RoundTrips()
    {
        await using var session = fixture.Store.LightweightSession();
        // ...
    }
}
```

`ResetAsync` wipes documents between tests without dropping the schema, so it belongs in `InitializeAsync`, not `DisposeAsync` — rebuilding the schema per test is the slow part this design avoids.

## Pointing a second consumer at the same database

`ConnectionString` exposes the container's connection string, so an app under test can boot its own Marten against the very database `Store` reads and writes — no second container, and no direct `Testcontainers.PostgreSql` reference in the consuming repo:

```csharp
protected override void ConfigureWebHost(IWebHostBuilder builder) =>
    builder.UseSetting("ConnectionStrings:Postgres", fixture.ConnectionString);
```

It throws `InvalidOperationException` before `InitializeAsync` has run — there is no container to ask yet.

## Extending the fixture

Some consumers need more than a vanilla store — `marten-identity`'s fixture calls `opts.InitializeIdentity()` and resolves an `ISettingsStore` once the store is built; a future consumer might need projections or its own settings documents.

**Design choice: inheritance with protected virtual hooks (template method), not composition via constructor-injected delegates.** xunit's `ICollectionFixture<T>` / `IClassFixture<T>` construct the fixture type themselves and require a public parameterless constructor — a delegate-based composition design would have nowhere natural to receive the delegates without reintroducing a parameterless-constructor problem one layer up (a static factory, an ambient/service-locator pattern, ...). Subclassing sidesteps that entirely: the subclass's own parameterless constructor is what xunit calls, and `MartenFixture` exposes two `protected virtual` seams for it to override:

- `ConfigureStore(StoreOptions options)` — additional store configuration, run after the connection string is set and before `AutoCreateSchemaObjects` is applied. No-op by default.
- `OnStoreInitializedAsync()` — runs once `Store` is built; use it to resolve derived services (e.g. a settings store via DI) that need a live store. No-op by default.

`ResetAsync` is also `virtual` so a subclass can extend the cleanup (e.g. also clearing event data) while still calling the base document wipe.

This is why `MartenFixture` is `public` and unsealed, deviating from the ecosystem's "classes are `internal sealed` by default" rule — same kind of deliberate, documented exception as `MartenSettingsStore` in `AndreGoepel.Marten.Configuration`. Being an open extension point is the entire point of this type.

Example — the shape `marten-identity`'s fixture would take on this package (not applied in this repo; migrating `marten-identity` itself is a follow-up):

```csharp
public sealed class IdentityMartenFixture : MartenFixture
{
    public ISettingsStore SettingsStore { get; private set; } = null!;

    protected override void ConfigureStore(StoreOptions options) =>
        options.InitializeIdentity();

    protected override async ValueTask OnStoreInitializedAsync()
    {
        var services = new ServiceCollection();
        services.AddSingleton(Store);
        services.AddMartenConfiguration();
        SettingsStore = services.BuildServiceProvider().GetRequiredService<ISettingsStore>();
    }

    public override async Task ResetAsync(CancellationToken cancellationToken = default)
    {
        await base.ResetAsync(cancellationToken);
        await Store.Advanced.Clean.DeleteAllEventDataAsync(cancellationToken);
    }
}

[CollectionDefinition(Name)]
public sealed class IntegrationCollection : ICollectionFixture<IdentityMartenFixture>
{
    public const string Name = "Integration";
}
```

## Postgres version

The pinned image digest lives in `MartenFixture.PostgresImage` (currently `postgres:16-alpine@...`). Bump it in one place to move every consumer to a new Postgres version at once — that lockstep bump is the reason this package exists instead of two hand-copied fixtures.

## Requirements

Docker (or a compatible container runtime) must be available wherever tests run — locally and in CI. GitHub-hosted `ubuntu-latest` runners have Docker preinstalled.
