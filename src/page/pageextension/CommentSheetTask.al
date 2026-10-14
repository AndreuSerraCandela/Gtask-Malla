pageextension 80011 "CommentSheetTask" extends "Comment Sheet"
{
    layout
    {
        addafter(Comment)
        {
            field("Fecha Cobro/Proxima Gestión"; Rec."Fecha Cobro/Proxima Gestión")
            {
                ApplicationArea = All;
                ToolTip = 'Al indicar la fecha se crea una tarea de la categoría RECORDATORIO para ese día.';
                Visible = Rec."Table Name" = Rec."Table Name"::Customer;
            }
        }
    }
}
