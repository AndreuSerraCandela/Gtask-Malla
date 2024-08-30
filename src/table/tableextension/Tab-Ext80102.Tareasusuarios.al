/// <summary>
/// TableExtension Tareasusuarios (ID 90103) extends Record User Task.
/// </summary>
tableextension 92103 Tareasusuarios extends "User Task"
{
    fields
    {
        field(50000; Id_Tarea; Text[250])
        {
            Caption = 'Id_tarea';
            DataClassification = ToBeClassified;
        }
        field(50001; Supervisor; guid)
        {
            Caption = 'Supervisor';
            DataClassification = ToBeClassified;
            TableRelation = User."User Security ID";//WHERE("License Type" = CONST("Full User"));
            ValidateTableRelation = false;
            trigger OnLookup()
            var
                User: Record UsuariosGtask;
            begin
                If Page.RunModal(Page::UsuariosGtask, User) = Action::LookupOK then
                    Supervisor := user."Id Usuario";
            end;

        }

        field(50015; "Supervisor User Name"; Code[50])
        {
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("Supervisor")));
            Caption = 'Nombre Supervisor';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50002; "No."; Code[20])
        {

        }
        field(50003; "Line No."; Integer)
        {

        }
        field(50004; OrdenFijacion; Integer)
        {
            Caption = 'Orden Fijación';
        }
        field(50005; "Job No."; Code[20])
        {
            TableRelation = Job."No.";
        }
        //departamento
        field(50006; Departamento; Text[20])
        {
            Caption = 'Departamento';
            DataClassification = ToBeClassified;
            TableRelation = "Responsibility Center"."Code";
        }
        //servicio
        field(50007; Servicio; Text[20])
        {
            Caption = 'Servicio';
            DataClassification = ToBeClassified;
            TableRelation = "Work Center"."No.";
        }


        modify("Assigned To")
        {
            TableRelation = User."User Security ID";//WHERE("License Type" = CONST("Full User"));


        }
        modify("User Task Group Assigned To")
        {
            Caption = 'Categoría';

        }
        field(50008; Categoría; Code[20])
        {
            Caption = 'User Task Group Assigned To';
            DataClassification = CustomerContent;
            TableRelation = "User Task Group".Code;

            trigger OnValidate()
            var
                Categorias: Record "User Task Group Member";
            begin
                "User Task Group Assigned To" := Categoría;
                Categorias.SetRange("User Task Group Code", Categoría);
                Categorias.SetRange(Departamento, Departamento);
                Categorias.SetRange(Responsable, true);
                if Categorias.FindFirst() then
                    Validate("Assigned To", Categorias."User Security ID");

            end;
        }

    }
    trigger OnAfterDelete()
    var
        Gtask: Codeunit GTask;
    begin
        Gtask.DeleteTarea(Rec);
    end;
}
tableextension 90109 Tareascomercial extends "To-do"
{
    fields
    {
        field(50000; Id_Tarea; Text[250])
        {
            Caption = 'Id_tarea';
            DataClassification = ToBeClassified;
        }
        field(50001; Responsable; guid)
        {
            Caption = 'Responsable';
            DataClassification = ToBeClassified;
            TableRelation = User."User Security ID";//WHERE("License Type" = CONST("Full User"));


        }
        field(50002; Categoria; Code[20])
        {
            Caption = 'Categoría';
            DataClassification = ToBeClassified;
            TableRelation = "User Task Group"."Code";
        }
        field(50003; Departamento; Code[20])
        {
            Caption = 'Departamento';
            DataClassification = ToBeClassified;
            TableRelation = "Responsibility Center"."Code";
        }



    }
    trigger OnAfterModify()
    var
        Gtastk: Codeunit GTask;
    begin
        if ("Start Time" <> 0T) and (Id_Tarea = '') then
            Gtastk.CrearTareaTodo(Rec);
    end;

}