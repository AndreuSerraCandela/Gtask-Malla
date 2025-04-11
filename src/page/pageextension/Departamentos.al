pageextension 92161 Departamentos extends "Responsibility Center list"
{
    Caption = 'Departamentos';
    AdditionalSearchTerms = 'Departamentos';
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
                    Gtask.DeleteLink(Rec.RecordId, Database::"Responsibility Center", IDGtask, CompanyName);
                    Gtask.InsertLink(Rec.RecordId, Database::"Responsibility Center", IDGtask, CompanyName);
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
                    Gtask.SincronizarDepartamentos(CompanyName);
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
        IDGtask := Gtask.GetLink(Rec.RecordId, Database::"Responsibility Center", CompanyName);
    end;
}
