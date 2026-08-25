// ==========================================
// 1. SELECCIÓN DE ELEMENTOS
// ==========================================
const formGasto = document.getElementById('form-gasto');
const inputMotivo = document.getElementById('motivo');
const inputImporte = document.getElementById('importe');
const inputCategoria = document.getElementById('categoria');

const displayTotalGastos = document.getElementById('total-gastos');
const displayTotalDiferencia = document.getElementById('total-diferencia');
const displayTotalIngresos = document.getElementById('total-ingresos');

const tablaMovimientos = document.getElementById('lista-movimientos');
const btnBorrarTodo = document.getElementById('btn-borrar-todo');

// Ingreso simulado por el momento
let ingresoMensual = 1275000; 
displayTotalIngresos.innerText = `$ ${ingresoMensual.toLocaleString('es-AR')}`;

// Recuperar gastos desde el LocalStorage o iniciar arreglo vacío
let listaGastos = JSON.parse(localStorage.getItem('misGastos')) || [];

// ==========================================
// 2. FUNCIONES LÓGICAS
// ==========================================

// Función central para actualizar toda la pantalla a la vez
function actualizarPantalla() {
    actualizarBalances();
    renderizarLista();
}

function actualizarBalances() {
    let totalGastos = listaGastos.reduce((acumulador, gasto) => acumulador + gasto.importe, 0);
    let diferencia = ingresoMensual - totalGastos;

    displayTotalGastos.innerText = `$ ${totalGastos.toLocaleString('es-AR')}`;
    displayTotalDiferencia.innerText = `$ ${diferencia.toLocaleString('es-AR')}`;
}

// Función: Dibuja la lista de gastos en el HTML
function renderizarLista() {
    tablaMovimientos.innerHTML = ''; // Vaciamos la tabla para que no se dupliquen los datos

    listaGastos.forEach(gasto => {
        const fila = document.createElement('tr');
        
        fila.innerHTML = `
            <td>${gasto.fecha}</td>
            <td>${gasto.motivo}</td>
            <td><span class="badge pago" style="background: rgba(255,255,255,0.1); color: var(--text-main); border: 1px solid rgba(255,255,255,0.2);">${gasto.categoria}</span></td>
            <td style="font-weight: bold; color: var(--color-gasto);">$${gasto.importe.toLocaleString('es-AR')}</td>
            <td>
                <button onclick="borrarGastoUnico(${gasto.id})" style="background:none; border:none; color: var(--color-gasto); cursor:pointer; font-weight:bold; font-size:1.2rem; transition: transform 0.2s;">✖</button>
            </td>
        `;
        
        tablaMovimientos.appendChild(fila);
    });
}

function guardarDatos() {
    localStorage.setItem('misGastos', JSON.stringify(listaGastos));
}

// Función: Borrar un solo gasto
function borrarGastoUnico(idGasto) {
    listaGastos = listaGastos.filter(gasto => gasto.id !== idGasto);
    guardarDatos();
    actualizarPantalla();
}

// ==========================================
// 3. EVENTOS
// ==========================================

formGasto.addEventListener('submit', function(evento) {
    evento.preventDefault();

    const nuevoGasto = {
        id: Date.now(), 
        motivo: inputMotivo.value,
        importe: parseFloat(inputImporte.value),
        categoria: inputCategoria.value,
        fecha: new Date().toLocaleDateString('es-AR')
    };

    listaGastos.push(nuevoGasto);

    guardarDatos();
    actualizarPantalla();

    formGasto.reset();
    inputMotivo.focus();
});

// Evento: Borrar todo
btnBorrarTodo.addEventListener('click', function() {
    if (confirm('¿Estás seguro de que querés borrar TODOS los movimientos? Esta acción no se puede deshacer.')) {
        listaGastos = [];
        guardarDatos();
        actualizarPantalla();
    }
});

// ==========================================
// 4. INICIALIZACIÓN
// ==========================================
actualizarPantalla();
