pageextension 92162 Servicios extends "Work Center List"
{
    Caption = 'Servicios';
    AdditionalSearchTerms = 'Servicios';
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
}
