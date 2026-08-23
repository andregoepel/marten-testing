using AndreGoepel.Marten.Testing.Tests.Infrastructure;
using Marten;

namespace AndreGoepel.Marten.Testing.Tests;

/// <summary>
/// Smoke-tests the fixture itself: does it actually spin up a usable Postgres-backed
/// Marten store, and does <see cref="MartenFixture.ResetAsync"/> actually wipe it.
/// </summary>
public sealed class MartenFixtureTests(MartenFixture fixture)
    : IClassFixture<MartenFixture>,
        IAsyncLifetime
{
    private CancellationToken Ct => TestContext.Current.CancellationToken;

    public async ValueTask InitializeAsync() => await fixture.ResetAsync(Ct);

    public ValueTask DisposeAsync() => ValueTask.CompletedTask;

    [Fact]
    public async Task InitializeAsync_ContainerStarted_StoreRoundTripsADocument()
    {
        // Act
        await using (var session = fixture.Store.LightweightSession())
        {
            session.Store(new SmokeTestDocument { Id = "smoke", Value = "hello" });
            await session.SaveChangesAsync(Ct);
        }

        var loaded = await fixture.Store.QuerySession().LoadAsync<SmokeTestDocument>("smoke", Ct);

        // Assert
        Assert.NotNull(loaded);
        Assert.Equal("hello", loaded.Value);
    }

    [Fact]
    public async Task ResetAsync_AfterSavingADocument_ClearsIt()
    {
        // Arrange
        await using (var session = fixture.Store.LightweightSession())
        {
            session.Store(new SmokeTestDocument { Id = "to-reset", Value = "gone-soon" });
            await session.SaveChangesAsync(Ct);
        }

        // Act
        await fixture.ResetAsync(Ct);

        // Assert
        var loaded = await fixture
            .Store.QuerySession()
            .LoadAsync<SmokeTestDocument>("to-reset", Ct);
        Assert.Null(loaded);
    }

    [Fact]
    public async Task ConnectionString_ContainerStarted_PointsAtTheSameDatabaseAsStore()
    {
        // Arrange
        await using var secondStore = DocumentStore.For(fixture.ConnectionString);

        // Act
        await using (var session = secondStore.LightweightSession())
        {
            session.Store(new SmokeTestDocument { Id = "second-consumer", Value = "shared-db" });
            await session.SaveChangesAsync(Ct);
        }

        // Assert
        var loaded = await fixture
            .Store.QuerySession()
            .LoadAsync<SmokeTestDocument>("second-consumer", Ct);
        Assert.NotNull(loaded);
        Assert.Equal("shared-db", loaded.Value);
    }

    [Fact]
    public void ConnectionString_ContainerNotStarted_Throws()
    {
        // Arrange
        var uninitialized = new MartenFixture();

        // Act / Assert
        Assert.Throws<InvalidOperationException>(() =>
        {
            _ = uninitialized.ConnectionString;
        });
    }
}
