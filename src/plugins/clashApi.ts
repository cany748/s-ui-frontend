export interface TrafficData {
  up: number;
  down: number;
}

export interface ClashConnection {
  id: string;
  metadata: {
    network: string;
    type: string;
    sourceIP: string;
    destinationIP: string;
    host: string;
    inboundName?: string;
    user?: string;
  };
  upload: number;
  download: number;
  chains: string[];
}

export interface ConnectionsSnapshot {
  downloadTotal: number;
  uploadTotal: number;
  connections: ClashConnection[];
}

// Subscribe to Clash traffic SSE. Returns unsubscribe function.
export function subscribeTraffic(onData: (data: TrafficData) => void, onError?: () => void): () => void {
  const es = new EventSource("/cgi-bin/sui/clash/traffic");
  es.onmessage = (event) => {
    try {
      const data: TrafficData = JSON.parse(event.data);
      onData(data);
    } catch {
      // ignore parse errors
    }
  };
  es.onerror = () => {
    if (onError) onError();
  };
  return () => es.close();
}

// Fetch current connections snapshot
export async function getConnections(): Promise<ConnectionsSnapshot | null> {
  try {
    const resp = await fetch("/cgi-bin/sui/clash/connections");
    if (!resp.ok) return null;
    return (await resp.json()) as ConnectionsSnapshot;
  } catch {
    return null;
  }
}

// Fetch clash version
export async function getClashVersion(): Promise<{ version: string } | null> {
  try {
    const resp = await fetch("/cgi-bin/sui/clash/version");
    if (!resp.ok) return null;
    return await resp.json();
  } catch {
    return null;
  }
}
