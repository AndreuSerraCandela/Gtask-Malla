(function () {
    function escapeHtml(value) {
        return String(value == null ? '' : value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    function num(value) {
        return new Intl.NumberFormat('es-ES', { maximumFractionDigits: 0 }).format(Number(value || 0));
    }

    function kpi(label, value, note, state, action) {
        var actionClass = action ? ' tip-kpi-action' : '';
        var actionAttrs = action ? ' data-action="' + escapeHtml(action) + '" role="button" tabindex="0"' : '';
        return '<div class="tip-kpi ' + escapeHtml(state || '') + actionClass + '"' + actionAttrs + '>' +
            '<div class="tip-kpi-label">' + escapeHtml(label) + '</div>' +
            '<div class="tip-kpi-value">' + escapeHtml(value) + '</div>' +
            '<div class="tip-kpi-note">' + escapeHtml(note || '') + '</div>' +
            '</div>';
    }

    function metric(label, value, css, action) {
        var actionClass = action ? ' tip-kpi-action' : '';
        var actionAttrs = action ? ' data-action="' + escapeHtml(action) + '" role="button" tabindex="0"' : '';
        return '<div class="tip-financial-item' + actionClass + '"' + actionAttrs + '>' +
            '<div class="tip-financial-label">' + escapeHtml(label) + '</div>' +
            '<div class="tip-financial-value ' + escapeHtml(css || '') + '">' + escapeHtml(num(value)) + '</div>' +
            '</div>';
    }

    function taskCell(value, label, color, action) {
        var actionClass = action ? ' tip-kpi-action' : '';
        var actionAttrs = action ? ' data-action="' + escapeHtml(action) + '" role="button" tabindex="0"' : '';
        return '<div class="tip-task-cell' + actionClass + '"' + actionAttrs + '>' +
            '<div class="n" style="color:' + color + '">' + escapeHtml(value || 0) + '</div>' +
            '<div class="l">' + escapeHtml(label) + '</div></div>';
    }

    function taskBlock(title, t, prefix) {
        t = t || {};
        prefix = prefix || '';
        return '<div class="tip-card"><div class="tip-card-title">' + escapeHtml(title) + '</div>' +
            '<div class="tip-task-grid">' +
            taskCell(t.fin, 'Finalizadas', '#2f9e44', prefix + '-fin') +
            taskCell(t.pen, 'Pendientes', '#b7791f', prefix + '-pen') +
            taskCell(t.ven, 'Vencidas', '#d92d20', prefix + '-ven') +
            '</div></div>';
    }

    function incidentBlock(title, t, prefix) {
        t = t || {};
        prefix = prefix || '';
        return '<div class="tip-card"><div class="tip-card-title">' + escapeHtml(title) + '</div>' +
            '<div class="tip-task-grid">' +
            taskCell(t.taller, 'Incidencias taller', '#5c6ac4', prefix + '-taller') +
            taskCell(t.ordenes, 'Ordenes trabajo', '#b7791f', prefix + '-ordenes') +
            taskCell(t.progreso, 'En progreso', '#0b6bcb', prefix + '-progreso') +
            '</div></div>';
    }

    function donut(taskHealth) {
        var fin = Number(taskHealth.fin || 0);
        var pen = Number(taskHealth.pen || 0);
        var ven = Number(taskHealth.ven || 0);
        var total = Math.max(fin + pen + ven, 1);
        var penOffset = fin / total * 100;
        var venOffset = (fin + pen) / total * 100;

        return '<svg class="tip-donut" viewBox="0 0 42 42" role="img">' +
            '<circle cx="21" cy="21" r="15.915" fill="transparent" stroke="#e8edf2" stroke-width="8"></circle>' +
            segment('#2f9e44', fin / total * 100, 0) +
            segment('#b7791f', pen / total * 100, penOffset) +
            segment('#d92d20', ven / total * 100, venOffset) +
            '<text x="21" y="20" text-anchor="middle" font-size="5" font-weight="700" fill="#1f2933">' + escapeHtml(fin + pen + ven) + '</text>' +
            '<text x="21" y="25" text-anchor="middle" font-size="3" fill="#66788a">tareas</text>' +
            '</svg>';
    }

    function segment(color, value, offset) {
        if (!value) {
            return '';
        }
        return '<circle cx="21" cy="21" r="15.915" fill="transparent" stroke="' + color + '" stroke-width="8" ' +
            'stroke-dasharray="' + value + ' ' + (100 - value) + '" stroke-dashoffset="' + (25 - offset) + '"></circle>';
    }

    function objetivoCards(items) {
        if (!items || !items.length) {
            return '<div class="tip-empty">Ninguna parada del filtro tiene objetivo con periodo semana o mes.</div>';
        }
        return '<div class="tip-kpis">' + items.map(function (item) {
            var hechas = Number(item.hechas || 0);
            var objetivo = Number(item.objetivo || 0);
            var cumplen = Number(item.cumplen || 0);
            var paradas = Number(item.paradas || 0);
            var state = (paradas > 0 && cumplen === paradas) ? 'good' : (cumplen > 0 ? 'warning' : 'danger');
            return kpi(
                item.label,
                hechas + '/' + objetivo,
                cumplen + ' de ' + paradas + ' paradas cumplen',
                state,
                ''
            );
        }).join('') + '</div>';
    }

    function bars(items, fillClass) {
        if (!items || !items.length) {
            return '<div class="tip-empty">No hay datos con los filtros actuales.</div>';
        }
        var max = items.reduce(function (current, item) {
            return Math.max(current, Number(item.value || 0));
        }, 0) || 1;

        return '<div class="tip-bars">' + items.map(function (item) {
            var width = Math.max(3, Math.round(Number(item.value || 0) / max * 100));
            return '<div class="tip-bar-row">' +
                '<div class="tip-bar-label" title="' + escapeHtml(item.label) + '">' + escapeHtml(item.label) + '</div>' +
                '<div class="tip-bar-track"><div class="tip-bar-fill ' + (fillClass || 'good') + '" style="width:' + width + '%"></div></div>' +
                '<div class="tip-bar-value">' + escapeHtml(num(item.value)) + '</div>' +
                '</div>';
        }).join('') + '</div>';
    }

    function bindActions() {
        var actionItems = document.querySelectorAll('[data-action]');
        var index;

        function runAction(action) {
            var map = {
                'show-paradas': 'ShowParadas',
                'show-palos': 'ShowPalos',
                'show-marquesinas': 'ShowMarquesinas',
                'show-incidencias': 'ShowIncidencias',
                'show-ordenes': 'ShowOrdenesTrabajo',
                'inc-taller': 'ShowIncidencias',
                'inc-ordenes': 'ShowOrdenesTrabajo',
                'inc-progreso': 'ShowIncidenciasEnProgreso',
                'limp-fin': 'ShowLimpiezaFinalizadas',
                'limp-pen': 'ShowLimpiezaPendientes',
                'limp-ven': 'ShowLimpiezaVencidas',
                'rev-fin': 'ShowRevisionFinalizadas',
                'rev-pen': 'ShowRevisionPendientes',
                'rev-ven': 'ShowRevisionVencidas',
                'mant-programado': 'ShowMantenimientoProgramado',
                'mant-vencido': 'ShowMantenimientoVencido',
                'mant-aprobadas': 'ShowOrdenesTrabajoAprobadas',
                'mant-pendientes': 'ShowOrdenesTrabajoPendientes'
            };
            if (map[action]) {
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(map[action], []);
            }
        }

        function handleActivation(event) {
            var key = event.key || event.keyCode;
            if (event.type === 'keydown' && key !== 'Enter' && key !== ' ' && key !== 13 && key !== 32) {
                return;
            }
            event.preventDefault();
            runAction(event.currentTarget.getAttribute('data-action'));
        }

        for (index = 0; index < actionItems.length; index += 1) {
            actionItems[index].addEventListener('click', handleActivation);
            actionItems[index].addEventListener('keydown', handleActivation);
        }
    }

    window.Render = function (payload) {
        var data;
        try {
            data = JSON.parse(payload || '{}');
        } catch (error) {
            document.body.innerHTML = '<div class="tip-dashboard"><div class="tip-empty">No se pudo leer el panel.</div></div>';
            return;
        }

        var s = data.summary || {};
        var m = data.maintenance || {};
        var th = data.taskHealth || {};

        document.body.innerHTML =
            '<main class="tip-dashboard">' +
            '<section class="tip-header">' +
            '<div><div class="tip-title">Panel gerencia Paradas Bus</div>' +
            '<div class="tip-subtitle">Paradas, incidencias, limpieza, revision, mantenimiento y partes</div></div>' +
            '<div class="tip-pill">' + escapeHtml(data.period || '') + '</div>' +
            '</section>' +
            '<section class="tip-kpis">' +
            kpi('Total paradas', s.totalParadas || 0, 'abrir lista', '', 'show-paradas') +
            kpi('Palos (PA/PI)', s.palos || 0, 'tipo PA o PI', '', 'show-palos') +
            kpi('Marquesinas', s.marquesinas || 0, 'resto de tipos', 'good', 'show-marquesinas') +
            kpi('Incidencias abiertas', s.incidencias || 0, 'abrir lista', (s.incidencias || 0) > 0 ? 'warning' : 'good', 'show-incidencias') +
            kpi('Ordenes trabajo', s.ordenes || 0, 'peticiones abiertas', (s.ordenes || 0) > 0 ? 'danger' : 'good', 'show-ordenes') +
            '</section>' +
            '<section class="tip-card"><div class="tip-card-title">Objetivos del periodo</div>' +
            '<div class="tip-subtitle" style="margin:0 0 12px">' + escapeHtml(data.objetivoPeriodo || '') +
            '. Tareas finalizadas con fecha de inicio en la semana o el mes, según el periodo de cada parada.</div>' +
            objetivoCards(data.objetivos) +
            '</section>' +
            '<section class="tip-main-grid tip-main-grid--3">' +
            taskBlock('Limpieza', data.limpieza, 'limp') +
            taskBlock('Revision', data.revision, 'rev') +
            incidentBlock('Incidencias', data.incidencias, 'inc') +
            '</section>' +
            '<section class="tip-main-grid">' +
            '<div class="tip-card"><div class="tip-card-title">Estado global tareas</div><div class="tip-chart-row">' +
            donut(th) +
            '<div class="tip-legend">' +
            '<div class="tip-legend-item"><span class="tip-dot" style="background:#2f9e44"></span>Finalizadas: ' + escapeHtml(th.fin || 0) + '</div>' +
            '<div class="tip-legend-item"><span class="tip-dot" style="background:#b7791f"></span>Pendientes: ' + escapeHtml(th.pen || 0) + '</div>' +
            '<div class="tip-legend-item"><span class="tip-dot" style="background:#d92d20"></span>Vencidas: ' + escapeHtml(th.ven || 0) + '</div>' +
            '</div></div></div>' +
            '<div class="tip-card"><div class="tip-card-title">Mantenimiento y ordenes</div><div class="tip-financial">' +
            metric('Programadas 30 dias', m.programado, '', 'mant-programado') +
            metric('Mantenimiento vencido', m.vencido, (m.vencido || 0) > 0 ? 'tip-negative' : '', 'mant-vencido') +
            metric('Ordenes trabajo aprobadas', m.aprobadas, '', 'mant-aprobadas') +
            metric('Ordenes trabajo pendientes', m.pendientes, (m.pendientes || 0) > 0 ? 'tip-negative' : '', 'mant-pendientes') +
            '</div></div>' +
            '</section>' +
            '<section class="tip-main-grid">' +
            '<div class="tip-card"><div class="tip-card-title">Paradas por tipo</div>' + bars(data.topTipos || [], 'good') + '</div>' +
            '</section>' +
            '</main>';

        bindActions();
    };
})();
