using JasperFx;
using Marten;
using Testcontainers.PostgreSql;
using Xunit;

namespace AndreGoepel.Marten.Testing;

/// <summary>
/// Owns a Testcontainers-backed Postgres instance and a Marten <see cref="IDocumentStore"/>
/// for integration tests. Lives for the whole test collection so the container start-up
/// cost is paid once.
/// </summary>
/// <remarks>
/// Not sealed, and not <c>internal</c>, despite the ecosystem's default class visibility
/// rule: this type is the extension seam the whole package exists for. Consumers that need
/// extra store configuration (projections, settings documents, identity wiring, ...) subclass
/// and override <see cref="ConfigureStore"/> and <see cref="OnStoreInitializedAsync"/> instead
/// of re-implementing the container lifecycle. See the package README for the recipe.
/// </remarks>
public class MartenFixture : IAsyncLifetime
{
    // Pin the Postgres image by digest (not a mutable tag) so the test/CI environment can't
    // be fed a different image behind the same tag. Bump this to update the Postgres version
    // for every consumer at once — that lockstep bump is the whole reason this package exists.
    public const string PostgresImage =
        "postgres:16-alpine@sha256:e013e867e712fec275706a6c51c966f0bb0c93cfa8f51000f85a15f9865a28cb";

    private PostgreSqlContainer _container = null!;

    public IDocumentStore Store { get; private set; } = null!;

    public async ValueTask InitializeAsync()
    {
        _container = new PostgreSqlBuilder(PostgresImage).Build();
        await _container.StartAsync(TestContext.Current.CancellationToken);

        Store = DocumentStore.For(opts =>
        {
            opts.Connection(_container.GetConnectionString());
            ConfigureStore(opts);
            opts.AutoCreateSchemaObjects = AutoCreate.All;
        });

        await OnStoreInitializedAsync();
    }

    public async ValueTask DisposeAsync()
    {
        await Store.DisposeAsync();
        await _container.DisposeAsync();
    }

    /// <summary>
    /// Wipes documents between tests without dropping the schema (the schema rebuild is the
    /// slow part). Override to also clean up store-specific state, e.g. event streams —
    /// call the base implementation first.
    /// </summary>
    public virtual async Task ResetAsync(CancellationToken cancellationToken = default)
    {
        await Store.Advanced.Clean.DeleteAllDocumentsAsync(cancellationToken);
    }

    /// <summary>
    /// Extension point for additional <see cref="StoreOptions"/> configuration (projections,
    /// settings documents, identity wiring, ...). Runs after the connection string is set and
    /// before <c>AutoCreateSchemaObjects</c> is applied. No-op by default.
    /// </summary>
    protected virtual void ConfigureStore(StoreOptions options) { }

    /// <summary>
    /// Extension point that runs once <see cref="Store"/> is built, e.g. to resolve
    /// derived services (settings stores, DI-registered helpers) that need a live store.
    /// No-op by default.
    /// </summary>
    protected virtual ValueTask OnStoreInitializedAsync() => ValueTask.CompletedTask;
}
