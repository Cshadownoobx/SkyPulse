// ============================================================
// Aviation Website — Feature Flags (TypeScript)
// ============================================================

export type Environment = "dev" | "staging" | "prod";

export interface FeatureFlag {
  id: string;
  name: string;
  description: string;
  enabled: boolean;
  rolloutPercentage: number; // 0–100
  environments: Environment[];
}

// ── Flag definitions ─────────────────────────────────────────

const FLAGS: FeatureFlag[] = [
  {
    id: "live_flight_map",
    name: "Live flight map",
    description: "Real-time aircraft positions via ADS-B data.",
    enabled: true,
    rolloutPercentage: 100,
    environments: ["prod", "staging", "dev"],
  },
  {
    id: "flight_status_alerts",
    name: "Flight status alerts",
    description: "Push notifications for delays, gate changes, and arrivals.",
    enabled: true,
    rolloutPercentage: 100,
    environments: ["prod", "staging", "dev"],
  },
  {
    id: "airport_info_panel",
    name: "Airport info panel",
    description: "Terminal maps, lounges, and live security wait times.",
    enabled: true,
    rolloutPercentage: 100,
    environments: ["prod", "staging", "dev"],
  },
  {
    id: "flight_history",
    name: "Flight history tracker",
    description: "30-day history of any flight — delays, routes, on-time stats.",
    enabled: true,
    rolloutPercentage: 40,
    environments: ["staging", "dev"],
  },
  {
    id: "weather_overlay",
    name: "Weather overlay",
    description: "Radar, turbulence, and wind layers on the flight map.",
    enabled: true,
    rolloutPercentage: 60,
    environments: ["staging", "dev"],
  },
  {
    id: "airline_comparison",
    name: "Airline on-time comparison",
    description: "Compare punctuality scores across airlines and routes.",
    enabled: false,
    rolloutPercentage: 0,
    environments: ["dev"],
  },
  {
    id: "price_tracker",
    name: "Price tracker",
    description: "Track fare changes and receive price drop alerts.",
    enabled: false,
    rolloutPercentage: 0,
    environments: ["dev"],
  },
  {
    id: "co2_emissions",
    name: "CO₂ emissions estimate",
    description: "Carbon footprint per flight based on aircraft type and distance.",
    enabled: false,
    rolloutPercentage: 0,
    environments: ["dev"],
  },
];

// ── Flag manager ─────────────────────────────────────────────

export class FeatureFlagManager {
  private flags: Map<string, FeatureFlag>;
  private env: Environment;

  constructor(env: Environment) {
    this.env = env;
    this.flags = new Map(FLAGS.map((f) => [f.id, { ...f }]));
  }

  /**
   * Check if a flag is active for a given user.
   * Uses a stable hash of the userId so the same user always
   * gets the same result for partial rollouts.
   */
  isEnabled(flagId: string, userId?: string): boolean {
    const flag = this.flags.get(flagId);

    if (!flag) {
      console.warn(`[FeatureFlags] Unknown flag: "${flagId}"`);
      return false;
    }

    // Must be enabled and available in current environment
    if (!flag.enabled || !flag.environments.includes(this.env)) {
      return false;
    }

    // Full rollout — no bucketing needed
    if (flag.rolloutPercentage >= 100) return true;

    // Kill switch
    if (flag.rolloutPercentage <= 0) return false;

    // Partial rollout — bucket by userId if provided
    if (userId) {
      const bucket = this.hashUser(userId, flagId) % 100;
      return bucket < flag.rolloutPercentage;
    }

    // No userId — fall back to random
    return Math.random() * 100 < flag.rolloutPercentage;
  }

  /** Get a single flag's full config */
  getFlag(flagId: string): FeatureFlag | undefined {
    return this.flags.get(flagId);
  }

  /** Get all flags visible in the current environment */
  getAllForEnv(): FeatureFlag[] {
    return [...this.flags.values()].filter((f) =>
      f.environments.includes(this.env)
    );
  }

  /** Override a flag at runtime (e.g. from a remote config service) */
  override(flagId: string, patch: Partial<FeatureFlag>): void {
    const flag = this.flags.get(flagId);
    if (!flag) {
      console.warn(`[FeatureFlags] Cannot override unknown flag: "${flagId}"`);
      return;
    }
    this.flags.set(flagId, { ...flag, ...patch });
  }

  /** Stable hash: maps (userId + flagId) → 0..2³²-1 */
  private hashUser(userId: string, flagId: string): number {
    const str = `${userId}:${flagId}`;
    let hash = 2166136261; // FNV-1a 32-bit offset basis
    for (let i = 0; i < str.length; i++) {
      hash ^= str.charCodeAt(i);
      hash = (hash * 16777619) >>> 0; // 32-bit FNV prime
    }
    return hash;
  }
}

// ── Usage examples ────────────────────────────────────────────

/*

// 1. Initialise once (e.g. in your app's entry point)
const env = (process.env.APP_ENV as Environment) ?? "dev";
const flags = new FeatureFlagManager(env);

// 2. Check a flag (with a userId for consistent bucketing)
if (flags.isEnabled("live_flight_map", user.id)) {
  renderLiveMap();
}

// 3. Partial rollout — same user always gets the same result
if (flags.isEnabled("weather_overlay", user.id)) {
  showWeatherLayer();
}

// 4. Kill switch — disable instantly without a deploy
flags.override("live_flight_map", { enabled: false });

// 5. List all flags for the current environment
const activeFlags = flags.getAllForEnv();
console.log(activeFlags.map(f => `${f.name}: ${f.enabled}`));

*/
