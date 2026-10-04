/**
 * Context Status Extension
 *
 * Shows context-window usage on its own footer status line, so it stays
 * visible even on narrow terminals where the built-in stats line gets
 * truncated (context % is the last item there, so it's cut first).
 *
 * Renders e.g.:  ctx [█████░░░░░░░░░░] 34.2%  68.4k/200k
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const BAR_WIDTH = 15;
const STATUS_KEY = "context-status";

function formatTokens(n: number): string {
	if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
	if (n >= 1_000) return `${(n / 1_000).toFixed(1)}k`;
	return String(n);
}

function update(ctx: ExtensionContext): void {
	if (!ctx.hasUI) return;

	const theme = ctx.ui.theme;
	const usage = ctx.getContextUsage();

	if (!usage || usage.contextWindow <= 0) {
		ctx.ui.setStatus(STATUS_KEY, undefined);
		return;
	}

	const window = usage.contextWindow;

	// tokens/percent are null right after a compaction, until the next response.
	if (usage.percent === null || usage.tokens === null) {
		ctx.ui.setStatus(STATUS_KEY, theme.fg("dim", `ctx [${"░".repeat(BAR_WIDTH)}] ?  ?/${formatTokens(window)}`));
		return;
	}

	const percent = Math.max(0, Math.min(100, usage.percent));
	const filled = Math.min(BAR_WIDTH, Math.round((percent / 100) * BAR_WIDTH));
	const bar = "█".repeat(filled) + "░".repeat(BAR_WIDTH - filled);

	const color = percent > 90 ? "error" : percent > 70 ? "warning" : "success";
	const text = `${percent.toFixed(1)}%  ${formatTokens(usage.tokens)}/${formatTokens(window)}`;

	ctx.ui.setStatus(STATUS_KEY, `${theme.fg("dim", "ctx ")}${theme.fg(color, `[${bar}]`)} ${theme.fg("dim", text)}`);
}

export default function (pi: ExtensionAPI) {
	// Recompute whenever anything can move the context needle.
	for (const event of ["session_start", "message_end", "turn_end", "session_compact", "model_select"] as const) {
		pi.on(event, async (_e, ctx) => update(ctx));
	}
}
