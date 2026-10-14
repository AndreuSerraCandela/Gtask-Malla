/// <summary>
/// Evita que la bajada desde Gtask vuelva a encolar la misma tarea.
/// </summary>
codeunit 7001120 ColaGtaskEstado
{
    SingleInstance = true;

    var
        SuprimirEncolado: Boolean;

    procedure SetSuprimirEncolado(Suprimir: Boolean)
    begin
        SuprimirEncolado := Suprimir;
    end;

    procedure EstaSuprimido(): Boolean
    begin
        exit(SuprimirEncolado);
    end;
}
