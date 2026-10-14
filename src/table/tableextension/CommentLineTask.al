tableextension 80005 "CommentLineTask" extends "Comment Line"
{
    fields
    {
        field(50010; "Fecha Cobro/Proxima Gestión"; Date)
        {
            Caption = 'Fecha Cobro/Próxima Gestión';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CrearOActualizarRecordatorio();
            end;
        }
        field(50011; "Id Tarea Recordatorio"; Integer)
        {
            Caption = 'Id Tarea Recordatorio';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    local procedure CrearOActualizarRecordatorio()
    var
        UserTask: Record "User Task";
        Miembros: Record "User Task Group Member";
        Customer: Record Customer;
        Gtask: Codeunit GTask;
        Categoria: Code[20];
        Responsable: Guid;
        Supervisor: Guid;
        Departamento: Text[20];
        Titulo: Text;

    begin
        if Rec."Fecha Cobro/Proxima Gestión" = 0D then
            exit;

        if (Rec."Id Tarea Recordatorio" <> 0) and UserTask.Get(Rec."Id Tarea Recordatorio") then begin
            UserTask."Start DateTime" := CreateDateTime(Rec."Fecha Cobro/Proxima Gestión", 080000T);
            UserTask."Due DateTime" := CreateDateTime(Rec."Fecha Cobro/Proxima Gestión", 130000T);
            UserTask.Modify(true);
            if UserTask.Id_Tarea <> '' then
                Gtask.ActualizarVencimientoTarea(UserTask);
            exit;
        end;

        Categoria := 'RECORDATORIO';
        Miembros.SetRange("User Task Group Code", Categoria);
        Miembros.SetRange(Responsable, true);
        if not Miembros.FindFirst() then
            Error('Indique el responsable en la categoría %1.', Categoria);
        Responsable := Miembros."User Security ID";
        Departamento := CopyStr(Miembros.Departamento, 1, MaxStrLen(Departamento));
        Miembros.SetRange(Responsable);
        Miembros.SetRange(Supervisor, true);
        if not Miembros.FindFirst() then
            Error('Indique el supervisor en la categoría %1.', Categoria);
        Supervisor := Miembros."User Security ID";
        if Departamento = '' then
            Departamento := CopyStr(Miembros.Departamento, 1, MaxStrLen(Departamento));
        if Departamento = '' then
            Error('Indique el departamento en el responsable o el supervisor de la categoría %1.', Categoria);
        if IsNullGuid(Responsable) or IsNullGuid(Supervisor) then
            Error('El responsable y el supervisor de la categoría %1 deben ser usuarios de Gtask.', Categoria);

        Titulo := Rec.Comment;
        if (Rec."Table Name" = Rec."Table Name"::Customer) and Customer.Get(Rec."No.") then
            Titulo := Customer.Name + ' ' + Rec.Comment;
        Titulo := CopyStr('Recordatorio ' + Titulo, 1, MaxStrLen(UserTask.Title));

        Gtask.CrearCategorias(CompanyName);
        Commit();
        UserTask.Init();
        UserTask.Validate(Title, Titulo);
        UserTask.SetDescription(Rec.Comment);
        UserTask."Created By" := UserSecurityId();
        UserTask."Assigned To" := Responsable;
        UserTask.Supervisor := Supervisor;
        UserTask.Departamento := Departamento;
        UserTask.Servicio := Departamento;
        UserTask."User Task Group Assigned To" := Categoria;
        UserTask."Categoría" := Categoria;
        UserTask.Estado := UserTask.Estado::Pendiente;
        UserTask.Validate("Created DateTime", CurrentDateTime);
        UserTask."Start DateTime" := CreateDateTime(Rec."Fecha Cobro/Proxima Gestión", 080000T);
        UserTask."Due DateTime" := CreateDateTime(Rec."Fecha Cobro/Proxima Gestión", 130000T);
        UserTask.Validate(Priority, UserTask.Priority::Normal);
        UserTask."Object Type" := UserTask."Object Type"::Page;
        if (Rec."Table Name" = Rec."Table Name"::Customer) and Customer.Get(Rec."No.") then begin
            UserTask."Object ID" := Page::"Customer Card";
            UserTask.Id_record := Customer.RecordId;
        end;
        UserTask.Insert(true);
        UserTask."No." := Format(UserTask.ID);
        UserTask.Modify(true);
        Rec."Id Tarea Recordatorio" := UserTask.ID;
        Gtask.CrearTareaTecnico('', UserTask, UserTask.Departamento, UserTask.Servicio, false);
    end;
}
