// ============================================
// Lua Table Parser
// Converts Lua table constructor syntax (from CelestialRecruiter's serialize())
// to JavaScript objects.
//
// Expected input format:
//   { ["key"] = "value", ["nested"] = { [1] = "a", [2] = "b" }, }
// ============================================

class LuaParser {
  private input = '';
  private pos = 0;

  parse(input: string): unknown {
    this.input = input;
    this.pos = 0;
    this.skipWhitespaceAndComments();
    const result = this.parseValue();
    return result;
  }

  private peek(): string {
    return this.input[this.pos] || '';
  }

  private advance(): string {
    return this.input[this.pos++] || '';
  }

  private skipWhitespaceAndComments(): void {
    while (this.pos < this.input.length) {
      const ch = this.input[this.pos];
      // Whitespace
      if (ch === ' ' || ch === '\t' || ch === '\n' || ch === '\r') {
        this.pos++;
        continue;
      }
      // Lua single-line comment: --
      if (ch === '-' && this.input[this.pos + 1] === '-') {
        // Skip to end of line
        while (this.pos < this.input.length && this.input[this.pos] !== '\n') {
          this.pos++;
        }
        continue;
      }
      break;
    }
  }

  private parseValue(): unknown {
    this.skipWhitespaceAndComments();

    const ch = this.peek();

    if (ch === '{') return this.parseTable();
    if (ch === '"') return this.parseString();
    if (ch === "'") return this.parseSingleQuoteString();
    if (ch === '-' || (ch >= '0' && ch <= '9')) return this.parseNumber();

    // Keywords: true, false, nil
    if (this.matchKeyword('true')) return true;
    if (this.matchKeyword('false')) return false;
    if (this.matchKeyword('nil')) return null;

    throw new Error(`Unexpected character '${ch}' at position ${this.pos}`);
  }

  private matchKeyword(keyword: string): boolean {
    const slice = this.input.slice(this.pos, this.pos + keyword.length);
    if (slice === keyword) {
      // Make sure the keyword isn't part of a longer identifier
      const next = this.input[this.pos + keyword.length];
      if (next && /[a-zA-Z0-9_]/.test(next)) return false;
      this.pos += keyword.length;
      return true;
    }
    return false;
  }

  private parseString(): string {
    this.advance(); // skip opening "
    let result = '';
    while (this.pos < this.input.length) {
      const ch = this.advance();
      if (ch === '\\') {
        const esc = this.advance();
        switch (esc) {
          case 'n': result += '\n'; break;
          case 'r': result += '\r'; break;
          case 't': result += '\t'; break;
          case '\\': result += '\\'; break;
          case '"': result += '"'; break;
          case "'": result += "'"; break;
          default: result += esc; break;
        }
      } else if (ch === '"') {
        return result;
      } else {
        result += ch;
      }
    }
    throw new Error('Unterminated string');
  }

  private parseSingleQuoteString(): string {
    this.advance(); // skip opening '
    let result = '';
    while (this.pos < this.input.length) {
      const ch = this.advance();
      if (ch === '\\') {
        const esc = this.advance();
        switch (esc) {
          case 'n': result += '\n'; break;
          case 'r': result += '\r'; break;
          case 't': result += '\t'; break;
          case '\\': result += '\\'; break;
          case "'": result += "'"; break;
          case '"': result += '"'; break;
          default: result += esc; break;
        }
      } else if (ch === "'") {
        return result;
      } else {
        result += ch;
      }
    }
    throw new Error('Unterminated string');
  }

  private parseNumber(): number {
    const start = this.pos;
    if (this.peek() === '-') this.advance();
    while (this.pos < this.input.length && this.input[this.pos] >= '0' && this.input[this.pos] <= '9') {
      this.advance();
    }
    if (this.peek() === '.') {
      this.advance();
      while (this.pos < this.input.length && this.input[this.pos] >= '0' && this.input[this.pos] <= '9') {
        this.advance();
      }
    }
    // Scientific notation
    if (this.peek() === 'e' || this.peek() === 'E') {
      this.advance();
      if (this.peek() === '+' || this.peek() === '-') this.advance();
      while (this.pos < this.input.length && this.input[this.pos] >= '0' && this.input[this.pos] <= '9') {
        this.advance();
      }
    }
    const num = Number(this.input.slice(start, this.pos));
    if (isNaN(num)) throw new Error(`Invalid number at position ${start}`);
    return num;
  }

  private parseTable(): Record<string, unknown> | unknown[] {
    this.advance(); // skip {
    this.skipWhitespaceAndComments();

    const entries: Array<{ key: string | number; value: unknown }> = [];
    let hasNumericKeys = false;
    let hasStringKeys = false;

    while (this.peek() !== '}' && this.pos < this.input.length) {
      this.skipWhitespaceAndComments();
      if (this.peek() === '}') break;

      // Key = Value entry
      if (this.peek() === '[') {
        this.advance(); // skip [
        this.skipWhitespaceAndComments();

        let key: string | number;
        if (this.peek() === '"') {
          key = this.parseString();
          hasStringKeys = true;
        } else if (this.peek() === "'") {
          key = this.parseSingleQuoteString();
          hasStringKeys = true;
        } else {
          key = this.parseNumber();
          hasNumericKeys = true;
        }

        this.skipWhitespaceAndComments();
        if (this.peek() !== ']') throw new Error(`Expected ']' at position ${this.pos}`);
        this.advance(); // skip ]

        this.skipWhitespaceAndComments();
        if (this.peek() !== '=') throw new Error(`Expected '=' at position ${this.pos}`);
        this.advance(); // skip =

        this.skipWhitespaceAndComments();
        const value = this.parseValue();

        // Skip nil values
        if (value !== null) {
          entries.push({ key, value });
        }
      } else {
        // Implicit numeric key (array-style value without key)
        const value = this.parseValue();
        hasNumericKeys = true;
        if (value !== null) {
          entries.push({ key: entries.length + 1, value });
        }
      }

      this.skipWhitespaceAndComments();
      // Optional comma
      if (this.peek() === ',') {
        this.advance();
        this.skipWhitespaceAndComments();
      }
    }

    if (this.peek() !== '}') throw new Error(`Expected '}' at position ${this.pos}`);
    this.advance(); // skip }

    // Decide: if all keys are sequential numbers starting at 1, return array
    if (hasNumericKeys && !hasStringKeys) {
      const isSequential = entries.every((e, i) => e.key === i + 1);
      if (isSequential && entries.length > 0) {
        return entries.map(e => e.value);
      }
    }

    // Otherwise return object
    const obj: Record<string, unknown> = {};
    for (const entry of entries) {
      obj[String(entry.key)] = entry.value;
    }
    return obj;
  }
}

export type ParseResult = {
  success: true;
  data: Record<string, unknown>;
} | {
  success: false;
  error: string;
}

/**
 * Parse a Lua table constructor string into a JavaScript object.
 * Handles the format produced by CelestialRecruiter's serialize() function.
 */
export function parseLuaTable(input: string): ParseResult {
  if (!input || typeof input !== 'string') {
    return { success: false, error: 'Input is empty or not a string' };
  }

  const trimmed = input.trim();
  if (!trimmed.startsWith('{')) {
    return { success: false, error: 'Invalid format: data must start with {' };
  }

  try {
    const parser = new LuaParser();
    const result = parser.parse(trimmed);

    if (typeof result !== 'object' || result === null || Array.isArray(result)) {
      return { success: false, error: 'Invalid format: expected a table at root level' };
    }

    return { success: true, data: result as Record<string, unknown> };
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Unknown parsing error';
    return { success: false, error: `Parse error: ${message}` };
  }
}
