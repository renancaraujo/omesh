/// A set of utilities for hashing and encoding/decoding data
/// in the O'Mesh format.
///
/// To represent a mesh gradeient as binary data, use the
/// [OMeshBinaryFormatCodec] class.
///
/// To generate a hash from and to a hash String, use the
/// [getHashFromMesh] and [getMeshFromHash] functions.
library hash;

import 'package:mesh/hash.dart';

export 'src/hash/omesh_codec.dart';
export 'src/hash/omesh_hash.dart';
