using Microsoft.AspNetCore.Components;
using MudBlazor;

namespace QuickBite.AdminBlazor.Components;

public partial class ConfirmDialog
{
    [CascadingParameter] private MudDialogInstance MudDialog { get; set; } = default!;

    [Parameter] public string Text { get; set; } = string.Empty;
    [Parameter] public string? ConfirmText { get; set; }
    [Parameter] public string? CancelText { get; set; }
    [Parameter] public bool Danger { get; set; }
    [Parameter] public string? Icon { get; set; }

    private void Confirm() => MudDialog.Close(DialogResult.Ok(true));

    private void Cancel() => MudDialog.Cancel();
}