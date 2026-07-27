/// Durable states for the import state machine.
///
/// [importing] means the ciphertext has not yet passed verification and can
/// safely be discarded after a crash. [verified] is the critical commit
/// point: the encrypted blob round-tripped successfully and its hash is
/// already durable in SQLite, so recovery must preserve it even if deleting
/// the source was interrupted. [completed] is visible to the regular vault
/// queries.
enum ImportStatus { importing, verified, completed }
