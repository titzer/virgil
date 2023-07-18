import { EventEmitter } from 'events';
import { spawn } from 'child_process';
import { ChildProcessWithoutNullStreams } from 'node:child_process';
import { debug } from 'vscode';

interface IRuntimeStackFrame {
	index: number;
	name: string;
	file: string;
	line: number;
	column?: number;
}

interface IRuntimeBreakpoint {
	id: number;
	line: number;
	verified: boolean;
	ts: number;
	enable: boolean;
}

export interface IRuntimeVariable {
	name: string;
	type: string;
	value: string;
	reference: boolean;
	idx: number[];
}

export class DbgConnector extends EventEmitter {
	private debugger!: ChildProcessWithoutNullStreams;
	private stepEvent: string = '';
	private _stacktrace: IRuntimeStackFrame[] = [];
	private _localVariables: IRuntimeVariable[] = [];
	private _variableIdx: number[] = [];

	private _sourceFile: string[] = [];
	public get sourceFile() {
		return this._sourceFile;
	}

	private breakPoints = new Map<string, Map<number,IRuntimeBreakpoint>>();
	private breakpointTs = 0;
	private stopOnEntry = false;

	/**
	 * Start executing the given program.
	 */
	public start(command: string, program: string[], stopOnEntry: boolean): void {
		console.log('dbgConnector start')
		this._sourceFile = program;
		this.stopOnEntry = stopOnEntry;
		const debuggerArgs = ['-debug', '-debug-extension'].concat(program);

		this.debugger = spawn(command, debuggerArgs);

		this.debugger.stdout.on('data', data => {
			let lines = data.toString().split('\n');
			for (let line of lines) {
				if (line) this.parseStdout(line);
			}
		});
		this.debugger.stderr.on('data', data => {
			debug.activeDebugConsole.appendLine(data);
		});
		this.debugger.on('error', (error) => {
			debug.activeDebugConsole.appendLine(error.name + ': ' + error.message);
		});
	}

	public startDebugee() {
		if (this.stopOnEntry) {
			this.stepEvent = 'stopOnEntry';
			this.debugger.stdin.write("start\n");
			this.requestStackTrace();
		} else {
			this.stepEvent = 'stopOnStep';
			this.debugger.stdin.write("run\n");
			this.requestStackTrace();
			this.requestVariables();
		}
	}

	public disconnect() {
		this.debugger.stdin.write('q\n');
	}

	public step(cmd: string) {
		this.stepEvent = 'stopOnStep';
		this.debugger.stdin.write(cmd + '\n');
		this.requestStackTrace();
		this.requestVariables();
	}

	public stack(startFrame: number, endFrame: number): IRuntimeStackFrame[] {
		const frames: IRuntimeStackFrame[] = [];
		for (let i = 0; i < this._stacktrace.length; i ++) {
			let entry = this._stacktrace[i];
			frames.push({
				index: entry.index,
				name:  entry.name,
				file:  entry.file,
				line:  entry.line
			});
		}
		if (frames.length === 0) {
			frames.push({
				index: 0,
				name: "BOTTOM",
				file: this._sourceFile[0],
				line: -1,
			});
		}
		return frames;
	}

	public getLocalVariables() {
		return this._localVariables;
	}

	public async getLocalVariable(idx: number[]) {
		this._localVariables = [];
		this._variableIdx = idx;
		this.debugger.stdin.write(`info variable ${idx.join(' ')}\n`);
		await this.getPromiseFromEvent('getVariableDone');
		return this._localVariables;
	}

	private requestStackTrace() {
		this._stacktrace = [];
		this.debugger.stdin.write('bt\n');
	}

	private requestVariables() {
		this._localVariables = [];
		this._variableIdx = [];
		this.debugger.stdin.write('info l\n');
	}

	public async updateBreakPoint(path: string, lines: number[]): Promise<IRuntimeBreakpoint[]> {
		this.breakpointTs ++;
		let bps = this.breakPoints.get(path);
		if (!bps) {
			bps = new Map<number, IRuntimeBreakpoint>();
			this.breakPoints.set(path, bps);
		}
		const actualBreakpoints0 = lines.map(async (line, index, array) => {
			let bp = bps!.get(line);
			if (!bp) {
				bp = await this.setBreakPoint(path, line);
				if (bp.verified) {
					bp.ts = this.breakpointTs;
					bps!.set(bp.line, bp);
				}
				return bp;
			} else {
				if (!bp.enable) {
					this.debugger.stdin.write(`enable ${bp.id}\n`);
					bp.enable = true;
				}
				bp.ts = this.breakpointTs;
				return bp;
			}
		})
		const actualBreakpoints = await Promise.all<IRuntimeBreakpoint>(actualBreakpoints0);

		for (let [_, bp] of bps) {
			if (bp.ts != this.breakpointTs && bp.enable) {
				this.debugger.stdin.write(`disable ${bp.id}\n`);
				bp.enable = false;
			}
		}
		return actualBreakpoints;
	}

	private async setBreakPoint(path: string, line: number): Promise<IRuntimeBreakpoint> {
		this.debugger.stdin.write(`b ${path} ${line}\n`);
		const id = await this.getPromiseFromEvent(`setBreakDone${path} ${line}`);
		if (id == -1) return <IRuntimeBreakpoint>{verified: false};
		else return <IRuntimeBreakpoint>{id, line, verified: true, enable: true};
	}

	private getPromiseFromEvent(event: string) {
		return new Promise<number>((resolve) => {
			const listener = (idx: number) => {
				resolve(idx);
			}
			this.once(event, listener);
		})
	}

	private parseStdout(data: string) {
		if (this.stepEvent) {
			if (data == 'end' || data == 'stopOnBreakpoint') this.sendEvent(data);
			else this.sendEvent(this.stepEvent);
			this.stepEvent = '';
			return;
		}
		const par = data.split('|');
		switch(par[0]) {
		case 'bt':
			this._stacktrace.push({
				index: 0,
				name: par[1],
				file: par[2],
				line: parseInt(par[3]),
			});
			break;
		case 'breakpoint':
			this.sendEvent('setBreakDone' + par[1], parseInt(par[2]));
			break;
		case 'variable':
			let item: IRuntimeVariable = {
				idx: this._variableIdx.concat(parseInt(par[1])),
				name: par[2],
				value: par[3],
				type: par[4],
				reference: (par[5] == 'true')? true : false,
			}
			this._localVariables.push(item);
			break;
		case 'variableDone':
			this.sendEvent('getVariableDone', 0);
			break;
		case 'result':
			debug.activeDebugConsole.appendLine('Program exited with result: ' + par[1]);
			break;
		} 
	}

	private sendEvent(event: string, ... args: any[]): void {
		setTimeout(() => {
			this.emit(event, ...args);
		}, 0);
	}
}