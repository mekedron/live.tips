# What this changes

<!-- One paragraph. What is different after this lands, from the artist's or fan's point of view. -->

Closes #

# How it was verified

<!--
Not "the tests pass" — this project has shipped green suites over a broken production
more than once, because the fakes model server truth while real Firestore answers from
cache first. Say what you actually drove, and where.
-->

- [ ] Tests pass (`flutter test`, `npm test` in `firebase/functions/`)
- [ ] Exercised the real flow end-to-end (say where: emulator, staging, a device, a venue tablet)
- [ ] If it touches Firestore reads: checked behaviour with a **cold cache** and while **offline**
- [ ] If it touches rules or callables: verified against the real backend, not only the fakes

# Risk

<!-- What could this break that the diff doesn't obviously touch? What did you decide not to fix here? -->
