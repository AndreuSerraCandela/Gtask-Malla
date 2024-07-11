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

        }
        field(50002; "No."; Code[20])
        {

        }
        field(50003; "Line No."; Integer)
        {

        }


        modify("Assigned To")
        {
            TableRelation = User."User Security ID";//WHERE("License Type" = CONST("Full User"));

        }
        modify("User Task Group Assigned To")
        {
            Caption = 'Categoría';
        }
    }
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