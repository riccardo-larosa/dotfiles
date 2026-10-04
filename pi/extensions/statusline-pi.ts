/**
 * statusline-pi — custom footer extension
 *
 * Segments (left → right, separated by │):
 *   dir  │  branch [changed]  │  context remaining (zone)  │  tok/s  │  $cost  │  🔧 tools  │  ⏱ idle  │  model [thinking]
 *
 * Additions over the original luongnv89/pi-extensions version:
 *   1. Cost tracking  — cumulative session cost from assistant usage
 *   2. Tool call counter — count of tool executions this session
 *   3. Idle timer — "1m ago" style time-since-last-response ticker
 */

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { execFileSync } from "node:child_process";
import * as path from "node:path";

// ─── Types ────────────────────────────────────────────────────────────────────

interface GitInfo {
	branch?: string;
	changedFiles: number;
}

interface ResponseSpeedAggregate {
	totalOutputTokens: number;
	totalDurationMs: number;
	responseCount: number;
}

interface CurrentResponseSpeed {
	outputTokens: number;
	durationMs: number;
	inProgress: boolean;
}

interface ResponseSpeedInfo {
	tokensPerSecond?: number;
	outputTokens: number;
	durationMs: number;
	responseCount: number;
	inProgress: boolean;
}

// ─── Constants ────────────────────────────────────────────────────────────────

const GIT_REFRESH_MS = 5_000;
const SPEED_RENDER_THROTTLE_MS = 250;
const IDLE_TICK_MS = 10_000; // redraw every 10s when idle

// ─── Extension ────────────────────────────────────────────────────────────────

export default function statuslinePiExtension(pi: ExtensionAPI) {
	let enabled = true;

	// Git state
	let gitInfo: GitInfo = { changedFiles: 0 };
	let lastGitRefresh = 0;

	// Response speed tracking
	let completedResponseSpeed = createEmptyAggregate();
	let responseStartMs: number | undefined;
	let liveOutputTokenEstimate = 0;
	let lastSpeedRender = 0;
	let responseSpeed: ResponseSpeedInfo | undefined;

	// === Feature 1: cost tracking ===
	let sessionCost = 0; // cumulative USD

	// === Feature 2: tool call counter ===
	let toolCallCount = 0;

	// === Feature 3: idle timer ===
	let lastResponseEndMs: number | undefined;
	let idleTimer: ReturnType<typeof setInterval> | undefined;

	// Render plumbing
	let requestRenderFn: (() => void) | undefined;
	let gitRefreshTimer: ReturnType<typeof setInterval> | undefined;

	// ── Lifecycle ──────────────────────────────────────────────────────────────

	pi.on("session_start", async (_event, ctx) => {
		if (!ctx.hasUI) return;
		mount(ctx);
	});

	pi.on("session_shutdown", async () => {
		cleanup();
	});

	// ── Speed + cost tracking ──────────────────────────────────────────────────

	pi.on("message_start", async (event) => {
		if (event.message.role !== "assistant") return;
		responseStartMs = Date.now();
		liveOutputTokenEstimate = 0;
		responseSpeed = getAverageResponseSpeed(completedResponseSpeed, {
			outputTokens: 0,
			durationMs: 0,
			inProgress: true,
		});
		requestRender();
	});

	pi.on("message_update", async (event) => {
		if (event.message.role !== "assistant" || responseStartMs === undefined) return;
		const streamEvent = event.assistantMessageEvent;
		if (
			streamEvent.type === "text_delta" ||
			streamEvent.type === "thinking_delta" ||
			streamEvent.type === "toolcall_delta"
		) {
			liveOutputTokenEstimate += estimateTokens(streamEvent.delta);
		}
		responseSpeed = getAverageResponseSpeed(completedResponseSpeed, {
			outputTokens: Math.round(liveOutputTokenEstimate),
			durationMs: Date.now() - responseStartMs,
			inProgress: true,
		});
		throttledSpeedRender();
	});

	pi.on("message_end", async (event) => {
		if (event.message.role !== "assistant") {
			requestRender();
			return;
		}

		const durationMs = responseStartMs === undefined ? 0 : Date.now() - responseStartMs;
		const outputTokens =
			event.message.usage?.output ||
			estimateAssistantOutputTokens(event.message) ||
			Math.round(liveOutputTokenEstimate);

		if (responseStartMs !== undefined) {
			completedResponseSpeed = addCompletedSpeed(completedResponseSpeed, outputTokens, durationMs);
		}
		responseSpeed = getAverageResponseSpeed(completedResponseSpeed);
		responseStartMs = undefined;
		liveOutputTokenEstimate = 0;

		// === Feature 1: accumulate cost from this message ===
		const msgCost = (event.message as AssistantMessage).usage?.cost?.total ?? 0;
		sessionCost += msgCost;

		requestRender();
	});

	// === Feature 2: count tool executions ===
	pi.on("tool_execution_start", async () => {
		toolCallCount++;
		requestRender();
	});

	// === Feature 3: mark last-response time at turn_end ===
	pi.on("turn_end", async () => {
		lastResponseEndMs = Date.now();
		requestRender();
	});

	pi.on("tool_result", async (_event, ctx) => {
		refreshGit(ctx.cwd, true);
		requestRender();
	});

	pi.on("model_select", async () => {
		resetResponseSpeed();
		requestRender();
	});

	pi.on("thinking_level_select", async () => {
		resetResponseSpeed();
		requestRender();
	});

	// ── Commands ───────────────────────────────────────────────────────────────

	pi.registerCommand("statusline-pi", {
		description: "Toggle the statusline footer",
		handler: async (_args, ctx) => {
			if (!ctx.hasUI) return;
			enabled = !enabled;
			if (enabled) {
				mount(ctx);
				ctx.ui.notify("statusline-pi enabled", "info");
			} else {
				unmount(ctx);
				ctx.ui.notify("statusline-pi disabled", "info");
			}
		},
	});

	pi.registerCommand("statusline-refresh", {
		description: "Force-refresh statusline git data",
		handler: async (_args, ctx) => {
			refreshGit(ctx.cwd, true);
			requestRender();
			ctx.ui.notify("statusline refreshed", "info");
		},
	});

	// ── Mount / unmount ────────────────────────────────────────────────────────

	function mount(ctx: ExtensionContext): void {
		if (!enabled || !ctx.hasUI) return;

		refreshGit(ctx.cwd, true);

		ctx.ui.setFooter((tui, theme, footerData) => {
			const unsubBranch = footerData.onBranchChange(() => {
				refreshGit(ctx.cwd, true);
				tui.requestRender();
			});

			requestRenderFn = () => tui.requestRender();

			return {
				dispose() {
					unsubBranch();
					requestRenderFn = undefined;
				},
				invalidate() {
					tui.requestRender();
				},
				render(width: number): string[] {
					const usage = getUsage(ctx);
					const zone = getZone(usage.usedRatio, usage.contextWindow);
					const dir = path.basename(ctx.cwd) || ctx.cwd;
					const branch = gitInfo.branch ?? footerData.getGitBranch?.() ?? "no-git";

					const segments: string[] = [
						// dir
						theme.fg("mdLink", dir),

						// git: branch [N]
						formatGitSection(theme, branch, gitInfo.changedFiles),

						// context: remaining tokens + zone
						formatContextSection(theme, usage, zone),

						// tok/s speed
						formatSpeedSection(theme, responseSpeed),

						// === Feature 1: cost ===
						formatCostSection(theme, sessionCost),

						// === Feature 2: tool counter ===
						formatToolCount(theme, toolCallCount),

						// === Feature 3: idle timer ===
						formatIdleSection(theme, lastResponseEndMs),

						// model + thinking level
						formatModelName(ctx, pi, theme),
					].filter((s): s is string => Boolean(s));

					const sep = theme.fg("borderMuted", " │ ");
					const line = truncateToWidth(segments.join(sep), width);
					const extStatuses = Array.from(footerData.getExtensionStatuses?.().values() ?? []).map(
						(s) => truncateToWidth(s, width),
					);
					return [line, ...extStatuses];
				},
			};
		});

		// Git polling
		if (gitRefreshTimer) clearInterval(gitRefreshTimer);
		gitRefreshTimer = setInterval(() => {
			refreshGit(ctx.cwd);
			requestRender();
		}, GIT_REFRESH_MS);

		// === Feature 3: idle timer ===
		if (idleTimer) clearInterval(idleTimer);
		idleTimer = setInterval(() => {
			if (lastResponseEndMs !== undefined) requestRender();
		}, IDLE_TICK_MS);
	}

	function unmount(ctx: ExtensionContext): void {
		cleanup();
		ctx.ui.setFooter(undefined);
	}

	function cleanup(): void {
		if (gitRefreshTimer) clearInterval(gitRefreshTimer);
		if (idleTimer) clearInterval(idleTimer);
		gitRefreshTimer = undefined;
		idleTimer = undefined;
		requestRenderFn = undefined;
	}

	// ── Helpers ────────────────────────────────────────────────────────────────

	function requestRender(): void {
		requestRenderFn?.();
	}

	function throttledSpeedRender(): void {
		const now = Date.now();
		if (now - lastSpeedRender < SPEED_RENDER_THROTTLE_MS) return;
		lastSpeedRender = now;
		requestRender();
	}

	function resetResponseSpeed(): void {
		responseSpeed = undefined;
		completedResponseSpeed = createEmptyAggregate();
		responseStartMs = undefined;
		liveOutputTokenEstimate = 0;
		lastSpeedRender = 0;
	}

	function refreshGit(cwd: string, force = false): void {
		const now = Date.now();
		if (!force && now - lastGitRefresh < GIT_REFRESH_MS) return;
		lastGitRefresh = now;

		const branch = runGit(cwd, ["branch", "--show-current"]) || runGit(cwd, ["rev-parse", "--abbrev-ref", "HEAD"]);
		const porcelain = runGit(cwd, ["status", "--porcelain"]);
		const changedFiles = porcelain ? porcelain.split("\n").filter((l) => l.trim()).length : 0;

		gitInfo = { branch: branch || undefined, changedFiles };
	}
}

// ─── Segment formatters ───────────────────────────────────────────────────────

function formatGitSection(theme: ExtensionContext["ui"]["theme"], branch: string, changedFiles: number): string {
	const branchText = theme.fg("mdLink", branch);
	const changesColor = changedFiles > 0 ? "warning" : "dim";
	return `${branchText} ${theme.fg(changesColor, `[${changedFiles}]`)}`;
}

function formatContextSection(
	theme: ExtensionContext["ui"]["theme"],
	usage: ReturnType<typeof getUsage>,
	zone: string,
): string {
	const color = getZoneColor(zone);
	return theme.fg(color, `${usage.remainingTokens.toLocaleString()} (${usage.remainingPercent.toFixed(1)}%) ${zone}`);
}

function formatSpeedSection(theme: ExtensionContext["ui"]["theme"], speed: ResponseSpeedInfo | undefined): string {
	if (!speed) return theme.fg("dim", "-- tok/s");
	const speedText = speed.tokensPerSecond === undefined ? "--" : formatTokPerSec(speed.tokensPerSecond);
	const suffix = speed.inProgress ? "…" : "";
	return theme.fg(getSpeedColor(speed), `${speedText} tok/s${suffix}`);
}

// === Feature 1: cost segment ===
function formatCostSection(theme: ExtensionContext["ui"]["theme"], cost: number): string {
	if (cost === 0) return theme.fg("dim", "$0.000");
	// colour cheap sessions green, expensive ones orange/red
	const color = cost < 0.05 ? "success" : cost < 0.25 ? "warning" : "error";
	return theme.fg(color, `$${cost.toFixed(3)}`);
}

// === Feature 2: tool counter segment ===
function formatToolCount(theme: ExtensionContext["ui"]["theme"], count: number): string {
	if (count === 0) return theme.fg("dim", "🔧 0");
	const color = count < 20 ? "dim" : count < 50 ? "warning" : "error";
	return theme.fg(color, `🔧 ${count}`);
}

// === Feature 3: idle time segment ===
function formatIdleSection(theme: ExtensionContext["ui"]["theme"], lastMs: number | undefined): string | null {
	if (lastMs === undefined) return null;
	const elapsed = Date.now() - lastMs;
	const text = formatElapsed(elapsed);
	const color = elapsed < 60_000 ? "success" : elapsed < 300_000 ? "dim" : "muted";
	return theme.fg(color, `⏱ ${text}`);
}

function formatModelName(
	ctx: ExtensionContext,
	pi: ExtensionAPI,
	theme: ExtensionContext["ui"]["theme"],
): string {
	const provider = ctx.model?.provider;
	const model = ctx.model?.id ? ctx.model.id.replace(/^models\//, "") : "no-model";
	const supportsReasoning = ctx.model?.reasoning ?? false;
	const thinking = pi.getThinkingLevel?.() ?? "off";
	const thinkingDisplay = thinking !== "off" ? thinking : supportsReasoning ? "T" : "–";
	const modelPart = provider ? `${provider}/${model}` : model;
	return theme.fg("mdLink", `${modelPart} [${thinkingDisplay}]`);
}

// ─── Context usage ────────────────────────────────────────────────────────────

function getUsage(ctx: ExtensionContext) {
	const contextWindow = ctx.model?.contextWindow ?? 0;
	const usedTokens = ctx.getContextUsage?.()?.tokens ?? 0;
	const usedRatio = contextWindow > 0 ? Math.min(1, usedTokens / contextWindow) : 0;
	const remainingTokens = Math.max(0, contextWindow - usedTokens);
	const remainingPercent = contextWindow > 0 ? (remainingTokens / contextWindow) * 100 : 0;
	return { contextWindow, usedTokens, usedRatio, remainingTokens, remainingPercent };
}

function getZone(usedRatio: number, contextWindow: number): string {
	if (contextWindow >= 500_000) {
		const used = contextWindow * usedRatio;
		if (used < 150_000) return "Plan";
		if (used < 250_000) return "Code";
		if (used < 400_000) return "Dump";
		if (used < 450_000) return "ExDump";
		return "Dead";
	}
	if (usedRatio < 0.4) return "Plan";
	if (usedRatio < 0.7) return "Code";
	if (usedRatio < 0.75) return "Dump";
	if (usedRatio < 0.8) return "ExDump";
	return "Dead";
}

function getZoneColor(zone: string): "success" | "warning" | "error" | "dim" {
	switch (zone) {
		case "Plan":
		case "Code":
			return "success";
		case "Dump":
			return "warning";
		case "ExDump":
		case "Dead":
			return "error";
		default:
			return "dim";
	}
}

// ─── Response speed ───────────────────────────────────────────────────────────

function createEmptyAggregate(): ResponseSpeedAggregate {
	return { totalOutputTokens: 0, totalDurationMs: 0, responseCount: 0 };
}

function addCompletedSpeed(
	agg: ResponseSpeedAggregate,
	outputTokens: number,
	durationMs: number,
): ResponseSpeedAggregate {
	if (outputTokens <= 0 || durationMs <= 0) return agg;
	return {
		totalOutputTokens: agg.totalOutputTokens + outputTokens,
		totalDurationMs: agg.totalDurationMs + durationMs,
		responseCount: agg.responseCount + 1,
	};
}

function getAverageResponseSpeed(
	completed: ResponseSpeedAggregate,
	current?: CurrentResponseSpeed,
): ResponseSpeedInfo | undefined {
	const hasCurrentData = current !== undefined && current.outputTokens > 0 && current.durationMs > 0;
	const outputTokens = completed.totalOutputTokens + (hasCurrentData ? current.outputTokens : 0);
	const durationMs = completed.totalDurationMs + (hasCurrentData ? current.durationMs : 0);
	const inProgress = current?.inProgress ?? false;
	const tokensPerSecond = calcTokPerSec(outputTokens, durationMs);
	if (tokensPerSecond === undefined && !inProgress) return undefined;
	return {
		tokensPerSecond,
		outputTokens,
		durationMs,
		responseCount: completed.responseCount + (hasCurrentData ? 1 : 0),
		inProgress,
	};
}

function calcTokPerSec(tokens: number, durationMs: number): number | undefined {
	if (tokens <= 0 || durationMs <= 0) return undefined;
	return tokens / (durationMs / 1000);
}

function formatTokPerSec(n: number): string {
	return n < 100 ? n.toFixed(1) : Math.round(n).toString();
}

function getSpeedColor(speed: ResponseSpeedInfo): "success" | "warning" | "error" | "dim" {
	const t = speed.tokensPerSecond;
	if (t === undefined || t <= 0) return "dim";
	if (t >= 20) return "success";
	if (t >= 5) return "warning";
	return "error";
}

// ─── Token estimation ─────────────────────────────────────────────────────────

function estimateTokens(text: string): number {
	return Math.max(1, text.length / 4);
}

function estimateAssistantOutputTokens(
	message: { content: Array<{ type: string; text?: string; thinking?: string; arguments?: unknown }> },
): number {
	let chars = 0;
	for (const b of message.content) {
		if (b.type === "text") chars += b.text?.length ?? 0;
		else if (b.type === "thinking") chars += b.thinking?.length ?? 0;
		else if (b.type === "toolCall") chars += JSON.stringify(b.arguments ?? {}).length;
	}
	return Math.ceil(chars / 4);
}

// ─── Idle time formatting ─────────────────────────────────────────────────────

function formatElapsed(ms: number): string {
	const s = Math.floor(ms / 1000);
	if (s < 60) return `${s}s ago`;
	const m = Math.floor(s / 60);
	if (m < 60) return `${m}m ago`;
	const h = Math.floor(m / 60);
	return `${h}h ago`;
}

// ─── Git ──────────────────────────────────────────────────────────────────────

function runGit(cwd: string, args: string[]): string {
	try {
		return execFileSync("git", args, {
			cwd,
			encoding: "utf8",
			stdio: ["ignore", "pipe", "ignore"],
			timeout: 2_000,
		}).trim();
	} catch {
		return "";
	}
}
