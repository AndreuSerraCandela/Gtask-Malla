table 7010451 "Checklist Tarea Usuario"
{
    Caption = 'Checklist Tarea Usuario';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer)
        {
            Caption = 'Id tarea';
            DataClassification = CustomerContent;
            TableRelation = "User Task".ID;
            ValidateTableRelation = false;
        }
        field(2; "Categoría"; Code[20])
        {
            Caption = 'Categoría';
            DataClassification = CustomerContent;
            TableRelation = "User Task Group".Code;
        }
        field(3; "Nº Línea"; Integer)
        {
            Caption = 'Nº Línea';
            DataClassification = CustomerContent;
        }
        field(10; "Descripción"; Text[250])
        {
            Caption = 'Descripción';
            DataClassification = CustomerContent;
        }
        field(11; Obligatorio; Boolean)
        {
            Caption = 'Obligatorio';
            DataClassification = CustomerContent;
        }
        field(12; Completado; Boolean)
        {
            Caption = 'Completado';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if Completado then begin
                    if "Fecha Completado" = 0DT then
                        "Fecha Completado" := CurrentDateTime;
                    if "Completado por" = '' then
                        "Completado por" := CopyStr(UserId, 1, MaxStrLen("Completado por"));
                end else begin
                    Clear("Fecha Completado");
                    Clear("Completado por");
                end;
            end;
        }
        field(13; "Fecha Completado"; DateTime)
        {
            Caption = 'Fecha completado';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(14; "Completado por"; Code[50])
        {
            Caption = 'Completado por';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = User."User Name";
        }
    }

    keys
    {
        key(PK; Id, "Categoría", "Nº Línea")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if "Nº Línea" = 0 then
            "Nº Línea" := GetNextLineNo();
    end;

    procedure EsPlantilla(): Boolean
    begin
        exit(Id = 0);
    end;

    procedure TienePlantilla(Categoria: Code[20]): Boolean
    var
        ChecklistTareaUsuario: Record "Checklist Tarea Usuario";
    begin
        if Categoria = '' then
            exit(false);

        ChecklistTareaUsuario.SetRange(Id, 0);
        ChecklistTareaUsuario.SetRange("Categoría", Categoria);
        exit(not ChecklistTareaUsuario.IsEmpty());
    end;

    procedure TieneChecklistTarea(IdTarea: Integer; Categoria: Code[20]): Boolean
    var
        ChecklistTareaUsuario: Record "Checklist Tarea Usuario";
    begin
        if (IdTarea = 0) or (Categoria = '') then
            exit(false);

        ChecklistTareaUsuario.SetRange(Id, IdTarea);
        ChecklistTareaUsuario.SetRange("Categoría", Categoria);
        exit(not ChecklistTareaUsuario.IsEmpty());
    end;

    procedure CrearDesdePlantilla(IdTarea: Integer; Categoria: Code[20]): Boolean
    var
        ChecklistPlantilla: Record "Checklist Tarea Usuario";
        ChecklistTarea: Record "Checklist Tarea Usuario";
    begin
        if (IdTarea = 0) or (Categoria = '') then
            exit(false);
        if not TienePlantilla(Categoria) then
            exit(false);
        if TieneChecklistTarea(IdTarea, Categoria) then
            exit(false);

        ChecklistPlantilla.SetRange(Id, 0);
        ChecklistPlantilla.SetRange("Categoría", Categoria);
        if ChecklistPlantilla.FindSet() then
            repeat
                ChecklistTarea.Init();
                ChecklistTarea.Id := IdTarea;
                ChecklistTarea."Categoría" := Categoria;
                ChecklistTarea."Nº Línea" := ChecklistPlantilla."Nº Línea";
                ChecklistTarea."Descripción" := ChecklistPlantilla."Descripción";
                ChecklistTarea.Obligatorio := ChecklistPlantilla.Obligatorio;
                ChecklistTarea.Insert(true);
            until ChecklistPlantilla.Next() = 0;

        exit(true);
    end;

    local procedure GetNextLineNo(): Integer
    var
        ChecklistTareaUsuario: Record "Checklist Tarea Usuario";
    begin
        ChecklistTareaUsuario.SetRange(Id, Id);
        ChecklistTareaUsuario.SetRange("Categoría", "Categoría");
        if ChecklistTareaUsuario.FindLast() then
            exit(ChecklistTareaUsuario."Nº Línea" + 10000);

        exit(10000);
    end;
}
