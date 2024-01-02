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
            DataClassication = ToBeClassied;
        }
        field(50001; Supervisor; guid)
        {
            Caption = 'Supervisor';
            DataClassication = ToBeClassied;
            TableRelation = User."User Security ID";//WHERE("License Type" = CONST("Full User"));


        }
        mody("Assigned To")
        {
            TableRelation = User."User Security ID";//WHERE("License Type" = CONST("Full User"));
        }
        mody("User Task Group Assigned To")
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
            DataClassication = ToBeClassied;
        }
        field(50001; Responsable; guid)
        {
            Caption = 'Responsable';
            DataClassication = ToBeClassied;
            TableRelation = User."User Security ID";//WHERE("License Type" = CONST("Full User"));


        }
        field(50002; Categoria; Code[20])
        {
            Caption = 'Categoría';
            DataClassication = ToBeClassied;
            TableRelation = "User Task Group"."Code";
        }
        field(50003; Departamento; Code[20])
        {
            Caption = 'Departamento';
            DataClassication = ToBeClassied;
            TableRelation = "Responsibility Center"."Code";
        }



    }
    trigger OnAfterMody()
    var
        Gtastk: Codeunit GTask;
    begin
        ("Start Time" <> 0T) and (Id_Tarea = '') then
            Gtastk.CrearTareaTodo(Rec);
    end;

}