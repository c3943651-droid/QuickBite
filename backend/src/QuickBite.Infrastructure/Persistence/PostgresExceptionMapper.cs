using Microsoft.EntityFrameworkCore;
using Npgsql;
using QuickBite.Domain.Exceptions;

namespace QuickBite.Infrastructure.Persistence;

public static class PostgresExceptionMapper
{
    public static DomainException? Map(DbUpdateException exception)
    {
        if (exception.GetBaseException() is not PostgresException pg)
        {
            return null;
        }

        if (pg.SqlState == "23503")
        {
            return new ConflictException(
                "No se puede eliminar el registro porque tiene elementos asociados. Reasigna o elimínalos primero.");
        }

        return pg.MessageText switch
        {
            var message when message.StartsWith("Transición de estado no permitida", StringComparison.Ordinal) =>
                new BusinessRuleException(message, "INVALID_ORDER_TRANSITION"),
            var message when message.StartsWith("Solo se pueden asignar repartidores", StringComparison.Ordinal) =>
                new BusinessRuleException(message, "ORDER_NOT_READY_FOR_DELIVERY"),
            var message when message.Contains("no tiene rol repartidor") =>
                new BusinessRuleException(message, "DELIVERY_PERSON_NOT_FOUND"),
            var message when message.Contains("tiene pedidos activos") =>
                new BusinessRuleException(message, "DELIVERY_PERSON_HAS_ACTIVE_ORDERS"),
            var message when message.StartsWith("Stock insuficiente", StringComparison.Ordinal) =>
                new BusinessRuleException(message, "INSUFFICIENT_STOCK"),
            _ => null
        };
    }
}