using QuickBite.Domain.Entities;

namespace QuickBite.Application.Authentication;

public interface IJwtTokenGenerator
{
    AccessToken GenerateAccessToken(User user);
}

public sealed record AccessToken(string Value, DateTime ExpiraEn);
