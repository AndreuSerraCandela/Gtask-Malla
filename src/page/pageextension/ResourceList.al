pageextension 92174 "Resource List GTask Ext" extends "Resource List"
{
    actions
    {
        addlast(Processing)
        {
            action(AsignarZonaMantenimiento)
            {
                ApplicationArea = All;
                Caption = 'Asignar zona mantenimiento';
                Image = Apply;
                ToolTip = 'Asigna la misma zona de mantenimiento a todos los recursos seleccionados.';

                trigger OnAction()
                var
                    Resource: Record Resource;
                    Gtask: Codeunit Gtask;
                begin
                    CurrPage.SetSelectionFilter(Resource);
                    Gtask.AsignarZonaMantenimientoRecursos(Resource);
                end;
            }
        }
        addlast(Category_Process)
        {
            actionref(AsignarZonaMantenimiento_Promoted; AsignarZonaMantenimiento) { }
        }
    }
}
