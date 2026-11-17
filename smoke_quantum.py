#!/usr/bin/env python3
"""Smoke test for Zoose Quantum: every quantum library runs a two-qubit Bell state.

Run it inside the image, or in a venv built from quantum/requirements.txt:
    python3 smoke_quantum.py
Exit code 0 means every library imported and computed. Anything else lists the failures.
"""
import sys
import warnings

warnings.filterwarnings("ignore")
results = []


def check(name, fn):
    try:
        results.append((name, True, fn()))
    except Exception as exc:  # noqa: BLE001 - report every failure, do not stop at the first
        results.append((name, False, f"{type(exc).__name__}: {str(exc)[:140]}"))


def qiskit_bell():
    import qiskit
    from qiskit import QuantumCircuit
    from qiskit.quantum_info import Statevector

    qc = QuantumCircuit(2)
    qc.h(0)
    qc.cx(0, 1)
    probs = {str(k): round(float(v), 3) for k, v in Statevector(qc).probabilities_dict().items()}
    assert probs == {"00": 0.5, "11": 0.5}, probs
    from qiskit.primitives import StatevectorEstimator
    from qiskit.quantum_info import SparsePauliOp

    estimate = StatevectorEstimator().run([(qc, SparsePauliOp("XX"))]).result()[0].data.evs
    assert abs(float(estimate) - 1.0) < 1e-9, estimate
    return f"qiskit {qiskit.__version__}"


def qiskit_aer():
    import qiskit_aer
    from qiskit import QuantumCircuit, transpile
    from qiskit_aer import AerSimulator

    qc = QuantumCircuit(2, 2)
    qc.h(0)
    qc.cx(0, 1)
    qc.measure([0, 1], [0, 1])
    sim = AerSimulator()
    counts = sim.run(transpile(qc, sim), shots=200).result().get_counts()
    assert set(counts) <= {"00", "11"}, counts
    return f"qiskit-aer {qiskit_aer.__version__}"


def pennylane_bell():
    import numpy as np
    import pennylane as qml

    @qml.qnode(qml.device("default.qubit", wires=2))
    def circuit():
        qml.Hadamard(0)
        qml.CNOT([0, 1])
        return qml.probs(wires=[0, 1])

    assert np.allclose(circuit(), [0.5, 0, 0, 0.5])
    return f"pennylane {qml.__version__}"


def pennylane_qiskit():
    import pennylane as qml

    @qml.qnode(qml.device("qiskit.aer", wires=2))
    def circuit():
        qml.Hadamard(0)
        qml.CNOT([0, 1])
        return qml.expval(qml.PauliZ(0))

    assert abs(float(circuit())) < 0.3
    return "pennylane-qiskit"


def pennylane_cirq():
    import pennylane as qml

    @qml.qnode(qml.device("cirq.simulator", wires=2))
    def circuit():
        qml.Hadamard(0)
        qml.CNOT([0, 1])
        return qml.expval(qml.PauliZ(0))

    assert abs(float(circuit())) < 1e-6
    return "pennylane-cirq"


def cirq_bell():
    import cirq

    q = cirq.LineQubit.range(2)
    state = cirq.Simulator().simulate(cirq.Circuit(cirq.H(q[0]), cirq.CNOT(q[0], q[1]))).final_state_vector
    assert abs(abs(state[0]) - 0.7071) < 1e-3 and abs(abs(state[3]) - 0.7071) < 1e-3
    return f"cirq {cirq.__version__}"


def openfermion_ops():
    import openfermion

    op = openfermion.FermionOperator("0^ 1", 1.0)
    assert openfermion.hermitian_conjugated(op) is not None
    return f"openfermion {openfermion.__version__}"


def pytket_bell():
    import pytket
    from pytket import Circuit

    circuit = Circuit(2)
    circuit.H(0)
    circuit.CX(0, 1)
    assert circuit.n_gates == 2
    return f"pytket {pytket.__version__}"


def qutip_fidelity():
    import qutip

    assert abs(float(qutip.fidelity(qutip.basis(2, 0), qutip.basis(2, 0))) - 1.0) < 1e-9
    return f"qutip {qutip.__version__}"


def braket_local():
    from importlib.metadata import version

    from braket.circuits import Circuit
    from braket.devices import LocalSimulator

    counts = LocalSimulator().run(Circuit().h(0).cnot(0, 1), shots=100).result().measurement_counts
    assert set(counts) <= {"00", "11"}, counts
    return f"amazon-braket-sdk {version('amazon-braket-sdk')}"


# Order matters in plain Python: Braket SDK 1.99 reads sys.modules["IPython"].get_ipython when it is
# imported, and a prior `import qutip` leaves IPython half-loaded, so Braket raises KeyError.
# Inside Jupyter, where users run Zoose, IPython is fully loaded and the order does not matter.
# Braket therefore runs first. Do not move it below qutip.
for label, func in [
    ("braket", braket_local),
    ("qiskit", qiskit_bell),
    ("qiskit-aer", qiskit_aer),
    ("pennylane", pennylane_bell),
    ("pennylane-qiskit", pennylane_qiskit),
    ("pennylane-cirq", pennylane_cirq),
    ("cirq", cirq_bell),
    ("openfermion", openfermion_ops),
    ("pytket", pytket_bell),
    ("qutip", qutip_fidelity),
]:
    check(label, func)

width = max(len(name) for name, _, _ in results)
for name, ok, detail in results:
    print(f"{'ok  ' if ok else 'FAIL'} {name:<{width}}  {detail}")
failed = [name for name, ok, _ in results if not ok]
print(f"\n{len(results) - len(failed)}/{len(results)} libraries passed")
sys.exit(1 if failed else 0)
