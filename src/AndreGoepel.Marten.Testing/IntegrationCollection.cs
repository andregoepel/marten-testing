using Xunit;

namespace AndreGoepel.Marten.Testing;

/// <summary>
/// Ready-to-use xunit collection wired to the base <see cref="MartenFixture"/>, for consumers
/// that don't need extra store configuration.
/// </summary>
/// <remarks>
/// xunit collection fixtures are scoped per test assembly — a collection defined here can't be
/// shared as one physical container across multiple consuming assemblies, and consumers that
/// subclass <see cref="MartenFixture"/> can't reuse this definition either, since it's bound to
/// the base type and xunit would only ever construct <see cref="MartenFixture"/> itself. In
/// either case, define your own collection in your test project:
/// <code>
/// [CollectionDefinition(Name)]
/// public sealed class IntegrationCollection : ICollectionFixture&lt;YourMartenFixture&gt;
/// {
///     public const string Name = "Integration";
/// }
/// </code>
/// </remarks>
[CollectionDefinition(Name)]
public sealed class IntegrationCollection : ICollectionFixture<MartenFixture>
{
    public const string Name = "Integration";
}
