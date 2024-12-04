import subprocess
import time
import statistics
import matplotlib.pyplot as plt
import sys

def time_command(command, n):
    """Times a command N times and returns a list of timings."""
    timings = []

    for i in range(n):
        start = time.perf_counter()
        subprocess.run(command, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elapsed = time.perf_counter() - start
        timings.append(elapsed)
        print(f"Command: '{command}', Run {i + 1}: {elapsed:.4f} seconds")
    
    mean_time = statistics.mean(timings)
    variance_time = statistics.variance(timings) if len(timings) > 1 else 0

    return timings, mean_time, variance_time

def plot_statistics(commands, means, variances, output_file="command_stats_plot.png"):
    """Plots the means and variances of multiple commands."""
    x = range(len(commands))

    plt.bar(x, means, width=0.4, label='Mean', align='center', color='skyblue')
    plt.bar(x, variances, width=0.4, label='Variance', align='edge', color='orange')

    plt.xticks(x, commands, rotation=45, ha='right')
    plt.ylabel('Time (seconds)')
    plt.title('Command Execution Times: Means and Variances')
    plt.legend()
    plt.tight_layout()  # Ensure labels fit within the plot area
    plt.savefig(output_file)
    print(f"Plot saved as {output_file}")
    plt.show()

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python time_multiple_commands.py <number_of_runs> '<command1>' '<command2>' ...")
        sys.exit(1)

    n = int(sys.argv[1])
    commands = sys.argv[2:]

    means = []
    variances = []

    for command in commands:
        print(f"\nTiming command: '{command}'")
        _, mean_time, variance_time = time_command(command, n)
        means.append(mean_time)
        variances.append(variance_time)

    print("\nFinal Results:")
    for i, command in enumerate(commands):
        print(f"Command: '{command}' - Mean: {means[i]:.4f} s, Variance: {variances[i]:.4f} s^2")

    # Plot the means and variances
    plot_statistics(commands, means, variances)
