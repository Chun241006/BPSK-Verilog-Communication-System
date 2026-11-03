
import unittest

from golden_model import (
    CARRIER,
    bpsk_modulate,
    apply_channel,
    bpsk_demodulate,
    count_errors,
    simulate,
)


class TestGoldenModel(unittest.TestCase):

    def test_modulation(self):
        expected = list(CARRIER) + [-x for x in CARRIER]
        self.assertEqual(bpsk_modulate([0, 1]), expected)

    def test_channel(self):
        tx = bpsk_modulate([0, 1, 0])
        rx = apply_channel(tx, error_index=1)

        self.assertEqual(rx[:8], tx[:8])
        self.assertEqual(rx[8:16], [-x for x in tx[8:16]])
        self.assertEqual(rx[16:], tx[16:])

    def test_demodulation(self):
        samples = bpsk_modulate([0, 1])
        recovered, correlations = bpsk_demodulate(samples)

        self.assertEqual(recovered, [0, 1])
        self.assertEqual(correlations, [3999396, -3999396])

    def test_end_to_end(self):
        bits = [0, 1, 0, 1]
        tx, rx, recovered, errors, correlations = simulate(
            bits, error_index=2
        )

        self.assertEqual(recovered, [0, 1, 1, 1])
        self.assertEqual(errors, 1)
        self.assertEqual(len(tx), 32)
        self.assertEqual(len(rx), 32)
        self.assertEqual(
            correlations,
            [3999396, -3999396, -3999396, -3999396]
        )

    def test_error_count(self):
        tx = [0, 1, 1, 0]
        rx = [0, 0, 1, 1]

        self.assertEqual(count_errors(tx, rx), 2)

    def test_empty_input(self):
        self.assertEqual(simulate([]), ([], [], [], 0, []))

    def test_invalid_input(self):
        with self.assertRaises(ValueError):
            bpsk_modulate([2])

        with self.assertRaises(ValueError):
            bpsk_demodulate([1])


if __name__ == "__main__":
    unittest.main()
