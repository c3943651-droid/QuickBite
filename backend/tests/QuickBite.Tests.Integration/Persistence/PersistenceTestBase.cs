namespace QuickBite.Tests.Integration.Persistence;

public abstract class PersistenceTestBase : IClassFixture<PostgresDatabaseFixture>
{
    protected readonly PostgresDatabaseFixture Db;

    protected PersistenceTestBase(PostgresDatabaseFixture db)
    {
        Db = db;
    }

    protected bool CanRun() => Db.Available;
}