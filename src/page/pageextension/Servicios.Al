pageextension 92166 Servicios extends "Work Center List"
{
    Caption = 'Servicios';
    AdditionalSearchTerms = 'Servicios';
    layout
    {
        addlast(Control1)
        {
            field("Id Gtask"; IDGtask)
            {
                ApplicationArea = All;
                Caption = 'Id Kuara';
                ToolTip = 'Id Kuara';
                editable = false;
                trigger OnValidate()
                var
                    Gtask: Codeunit Gtask;
                begin
                    Gtask.DeleteLink(Rec.RecordId, Database::"Work Center", IDGtask, CompanyName);
                    Gtask.InsertLink(Rec.RecordId, Database::"Work Center", IDGtask, CompanyName);
                end;
            }
        }
    }
    actions
    {
        addlast(navigation)
        {
            action(Sincronizar)
            {
                ApplicationArea = All;
                Caption = 'Sincronizar';
                Image = Import;
                trigger OnAction()
                var
                    Gtask: Codeunit Gtask;
                begin
                    Gtask.SincronizarServicios(CompanyName);
                end;
            }
        }
    }
    var
        IDGtask: Text;

    trigger OnAfterGetRecord()
    var
        Gtask: Codeunit Gtask;
    begin
        IDGtask := Gtask.GetLink(Rec.RecordId, Database::"Work Center", CompanyName);
    end;
}
