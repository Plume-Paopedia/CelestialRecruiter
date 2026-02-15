// ============================================
// Lua Table Serializer
// Converts JavaScript objects to Lua table constructor syntax
// compatible with CelestialRecruiter's deserialize() function.
//
// Output format:
//   { ["key"] = "value", ["nested"] = { [1] = "a", [2] = "b" }, }
// ============================================

function escapeString(s: string): string {
  return s
    .replace(/\\/g, '\\\\')
    .replace(/"/g, '\\"')
    .replace(/\n/g, '\\n')
    .replace(/\r/g, '\\r')
    .replace(/\0/g, '');
}

function serializeValue(value: unknown, indent: number): string {
  const indentStr = '  '.repeat(indent);

  if (value === null || value === undefined) {
    return 'nil';
  }

  if (typeof value === 'boolean') {
    return value ? 'true' : 'false';
  }

  if (typeof value === 'number') {
    if (!isFinite(value)) return '0';
    return String(value);
  }

  if (typeof value === 'string') {
    return '"' + escapeString(value) + '"';
  }

  if (Array.isArray(value)) {
    if (value.length === 0) return '{}';
    let result = '{\n';
    for (let i = 0; i < value.length; i++) {
      result += indentStr + '  [' + (i + 1) + '] = ' + serializeValue(value[i], indent + 1) + ',\n';
    }
    result += indentStr + '}';
    return result;
  }

  if (typeof value === 'object') {
    const entries = Object.entries(value);
    if (entries.length === 0) return '{}';
    let result = '{\n';
    for (const [key, val] of entries) {
      if (val === undefined) continue;
      const luaKey = '["' + escapeString(key) + '"]';
      result += indentStr + '  ' + luaKey + ' = ' + serializeValue(val, indent + 1) + ',\n';
    }
    result += indentStr + '}';
    return result;
  }

  return 'nil';
}

/**
 * Serialize a JavaScript object to Lua table constructor syntax.
 * Produces output compatible with CelestialRecruiter's deserialize() function.
 */
export function serializeToLua(obj: Record<string, unknown>): string {
  return serializeValue(obj, 0);
}
