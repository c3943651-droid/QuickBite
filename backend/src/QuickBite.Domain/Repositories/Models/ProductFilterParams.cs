namespace QuickBite.Domain.Repositories.Models;

public class ProductFilterParams
{
    public Guid? CategoryId { get; set; }
    public string? SearchTerm { get; set; }
    public bool? OnlyAvailable { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public string? SortBy { get; set; }
    public bool SortDescending { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 10;
}
