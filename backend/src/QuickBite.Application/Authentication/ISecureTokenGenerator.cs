namespace QuickBite.Application.Authentication;

public interface ISecureTokenGenerator
{
    string Generate();
    string Hash(string token);
}
