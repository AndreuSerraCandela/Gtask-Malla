pageextension 92161 Departamentos extends "Responsibility Center list"
{
    Caption = 'Departamentos';
    AdditionalSearchTerms = 'Departamentos';

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
}
