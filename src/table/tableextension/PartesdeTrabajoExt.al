tableextension 92408 "Partes de Trabajo Ext" extends "Partes de Trabajo"
{
    fields
    {
        modify(Empleado)
        {

            trigger OnAfterValidate()
            begin
                if Empleado <> '' then
                    AgregarTareasFinalizadasEmpleado();
            end;
        }
    }

    local procedure AgregarTareasFinalizadasEmpleado()
    var
        UsuarioGtask: Record UsuariosGtask;
        UserTask: Record "User Task";
        DetalleParte: Record "Detalle Parte";
        NextLineNo: Integer;
        FechaFiltro: Date;
        Empresas: Record Company;
    begin
        TestField("Nº Parte");
        if not ResolverUsuarioGtaskEmpleado(Empleado, UsuarioGtask) then
            exit;

        FechaFiltro := "Fecha Parte";
        if FechaFiltro = 0D then
            FechaFiltro := WorkDate();


        DetalleParte.SetRange("Nº Parte", "Nº Parte");
        DetalleParte.SetRange(Tipo, DetalleParte.Tipo::Tarea);
        if DetalleParte.FindLast() then
            NextLineNo := DetalleParte."Nº Linea" + 10000
        else
            NextLineNo := 10000;
        if Empresas.FindFirst() then
            repeat
                UserTask.ChangeCompany(Empresas.Name);
                UserTask.SetRange("Assigned To", UsuarioGtask."Id Usuario");
                UserTask.SetRange(Estado, UserTask.Estado::Finalizado);
                UserTask.SetFilter(
                    "Fecha Cambio",
                    '>=%1&<=%2',
                    CreateDateTime(FechaFiltro, 0T),
                    CreateDateTime(FechaFiltro, 235959T));

                if UserTask.FindSet() then
                    repeat
                        DetalleParte.SetRange("Nº Parte", "Nº Parte");
                        DetalleParte.SetRange(Tipo, DetalleParte.Tipo::Tarea);
                        DetalleParte.SetRange("Nº Tarea", UserTask.ID);
                        if DetalleParte.IsEmpty() then begin
                            DetalleParte.Init();
                            DetalleParte."Nº Parte" := "Nº Parte";
                            DetalleParte.Tipo := DetalleParte.Tipo::Tarea;
                            DetalleParte."Nº Linea" := NextLineNo;
                            DetalleParte.Validate("Nº Tarea", UserTask.ID);
                            DetalleParte.Insert(true);
                            NextLineNo += 10000;
                        end;
                    until UserTask.Next() = 0;
            until Empresas.Next() = 0;
    end;

    local procedure ResolverUsuarioGtaskEmpleado(EmpleadoNo: Code[20]; var UsuarioGtask: Record UsuariosGtask): Boolean
    var
        Employee: Record Employee;
        TareaCompany: Text[30];
    begin
        TareaCompany := 'Malla Publicidad';


        UsuarioGtask.Reset();
        UsuarioGtask.ChangeCompany(TareaCompany);
        UsuarioGtask.SetRange(Empleado, EmpleadoNo);
        if UsuarioGtask.FindFirst() then
            exit(true);

        if TareaCompany <> 'Malla Publicidad' then begin
            TareaCompany := 'Malla Publicidad';
            UsuarioGtask.ChangeCompany(TareaCompany);
            UsuarioGtask.SetRange(Empleado, EmpleadoNo);
            if UsuarioGtask.FindFirst() then
                exit(true);
        end;

        if not Employee.ChangeCompany(TareaCompany) then
            Employee.ChangeCompany(CompanyName);
        if not Employee.Get(EmpleadoNo) then
            exit(false);
        if Employee.UserGtask = '' then
            exit(false);

        UsuarioGtask.Reset();
        UsuarioGtask.ChangeCompany(TareaCompany);
        UsuarioGtask.SetRange("Id Gtask", Employee.UserGtask);
        if UsuarioGtask.FindFirst() then
            exit(true);

        if TareaCompany <> CompanyName then begin
            TareaCompany := CopyStr(CompanyName, 1, MaxStrLen(TareaCompany));
            UsuarioGtask.ChangeCompany(TareaCompany);
            UsuarioGtask.SetRange("Id Gtask", Employee.UserGtask);
            exit(UsuarioGtask.FindFirst());
        end;

        exit(false);
    end;
}
