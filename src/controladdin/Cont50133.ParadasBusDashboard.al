controladdin "Paradas Bus Dashboard AddIn"
{
    HorizontalStretch = true;
    MinimumHeight = 560;
    RequestedHeight = 700;
    VerticalStretch = true;

    Scripts = 'src/controladdin/paradasBusDashboard.js';
    StartupScript = 'src/controladdin/paradasBusDashboardStartup.js';
    StyleSheets = 'src/controladdin/paradasBusDashboard.css';

    event ControlReady();
    event ShowParadas();
    event ShowPalos();
    event ShowMarquesinas();
    event ShowIncidencias();
    event ShowOrdenesTrabajo();
    event ShowIncidenciasEnProgreso();
    event ShowLimpiezaFinalizadas();
    event ShowLimpiezaPendientes();
    event ShowLimpiezaVencidas();
    event ShowRevisionFinalizadas();
    event ShowRevisionPendientes();
    event ShowRevisionVencidas();
    event ShowMantenimientoVencido();
    event ShowMantenimientoProgramado();
    event ShowOrdenesTrabajoAprobadas();
    event ShowOrdenesTrabajoPendientes();
    procedure Render(Payload: Text);
}
