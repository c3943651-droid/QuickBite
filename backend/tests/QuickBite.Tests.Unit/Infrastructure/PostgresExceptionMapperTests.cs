using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using QuickBite.Domain.Exceptions;
using QuickBite.Infrastructure.Persistence;

namespace QuickBite.Tests.Unit.Infrastructure;

public class PostgresExceptionMapperTests
{
    [Theory]
    [InlineData("Transición de estado no permitida: en_camino -> cancelado", "INVALID_ORDER_TRANSITION")]
    [InlineData("El usuario 11111111-1111-1111-1111-111111111111 no tiene rol repartidor", "DELIVERY_PERSON_NOT_FOUND")]
    [InlineData("Repartidor 22222222-2222-2222-2222-222222222222 tiene pedidos activos", "DELIVERY_PERSON_HAS_ACTIVE_ORDERS")]
    [InlineData("Stock insuficiente para producto 33333333-3333-3333-3333-333333333333", "INSUFFICIENT_STOCK")]
    [InlineData("Solo se pueden asignar repartidores a pedidos en estado 'listo' (estado actual: preparando)", "ORDER_NOT_READY_FOR_DELIVERY")]
    public void Map_ReturnsBusinessRuleException_WithExpectedRuleCode(string message, string ruleCode)
    {
        var mapped = PostgresExceptionMapper.Map(BuildDbUpdateException(message));

        mapped.Should().NotBeNull();
        mapped.Should().BeOfType<BusinessRuleException>();
        ((BusinessRuleException)mapped!).RuleCode.Should().Be(ruleCode);
        ((BusinessRuleException)mapped).Message.Should().Be(message);
    }

    [Fact]
    public void Map_ReturnsNull_WhenInnerExceptionIsNotPostgres()
    {
        var ex = new DbUpdateException("Error guardando cambios.", new InvalidOperationException("sin conexión"));

        var mapped = PostgresExceptionMapper.Map(ex);

        mapped.Should().BeNull();
    }

    private static DbUpdateException BuildDbUpdateException(string message)
    {
        var postgres = new PostgresException(
            messageText: message,
            severity: "ERROR",
            invariantSeverity: "ERROR",
            sqlState: "P0001",
            detail: string.Empty,
            hint: string.Empty,
            position: 0,
            internalPosition: 0,
            internalQuery: string.Empty,
            where: string.Empty,
            schemaName: string.Empty,
            tableName: string.Empty,
            columnName: string.Empty,
            dataTypeName: string.Empty,
            constraintName: string.Empty,
            file: string.Empty,
            line: string.Empty,
            routine: string.Empty);

        return new DbUpdateException("A ocurrido un error al guardar los cambios en la entidad.", postgres);
    }
}