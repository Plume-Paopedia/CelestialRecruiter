import { NextRequest, NextResponse } from 'next/server';

const FLASK_URL = process.env.FLASK_API_URL || 'http://localhost:5000';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { token, player, action } = body;

    if (!token) {
      return NextResponse.json({ error: 'Missing token' }, { status: 400 });
    }

    if (action === 'verify') {
      const res = await fetch(`${FLASK_URL}/claim/verify`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token }),
      });
      const data = await res.json();
      return NextResponse.json(data, { status: res.status });
    }

    if (action === 'claim') {
      if (!player) {
        return NextResponse.json({ error: 'Missing player name' }, { status: 400 });
      }
      const res = await fetch(`${FLASK_URL}/claim`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token, player }),
      });
      const data = await res.json();
      return NextResponse.json(data, { status: res.status });
    }

    return NextResponse.json({ error: 'Invalid action' }, { status: 400 });
  } catch (error) {
    console.error('Activate API error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
