import tkinter as tk
from tkinter import filedialog, messagebox, ttk
import subprocess
import shutil
import os
import threading
import time
import psutil
import re

video_count = 0  # To keep track of the total number of videos
last_processing_time = float('inf')  # Initialize to a high number
initial_video_count = 0
video_files = []  # To store paths of loaded videos
process = None
terminate = False

def get_nvidia_gpu_usage():
    try:
        result = subprocess.run(['nvidia-smi', '--query-gpu=utilization.gpu', '--format=csv,noheader'], text=True, capture_output=True)
        gpu_usage = result.stdout.strip().split(' ')[0]
        return gpu_usage
    except Exception as e:
        print(f"Failed to read GPU stats from nvidia-smi: {str(e)}")
        return "N/A"

def monitor_resources():
    global monitoring
    while monitoring:
        cpu_usage = psutil.cpu_percent(interval=1)
        gpu_usage = get_nvidia_gpu_usage()
        ram_usage = psutil.virtual_memory().percent
        cpu_label.config(text=f"CPU Usage: {cpu_usage}%")
        gpu_label.config(text=f"GPU Usage: {gpu_usage}%")
        ram_label.config(text=f"RAM Usage: {ram_usage}%")
        time.sleep(1)

def start_monitoring():
    global monitoring
    monitoring = True
    thread = threading.Thread(target=monitor_resources)
    thread.daemon = True
    thread.start()

def stop_monitoring():
    global monitoring
    monitoring = False

def start_countdown(time_left):
    def run_countdown():
        nonlocal time_left
        while time_left > 0:
            time.sleep(1)
            time_left -= 1
            app.after(0, lambda: countdown_label.config(text=f"Estimated time remaining: {time_left:.2f} seconds"))
        if time_left <= 0:
            app.after(0, lambda: countdown_label.config(text="Processing complete!"))

    countdown_thread = threading.Thread(target=run_countdown)
    countdown_thread.daemon = True
    countdown_thread.start()

def update_countdown():
    global last_processing_time, video_count, initial_video_count
    if video_count > 0:
        remaining_time = last_processing_time * video_count
        progress_var.set(100 * (1 - video_count / initial_video_count))
        start_countdown(remaining_time)  # Start or reset the countdown
    else:
        countdown_label.config(text="Processing complete!")
        progress_var.set(100)

def load_database_videos():
    global video_count, initial_video_count, video_files
    video_files = list(filedialog.askopenfilenames(title="Select Video Files", filetypes=[("Video files", "*.mp4")]))
    if video_files:  # Ensure files were selected
        successful = True
        for file_path in video_files:
            try:
                shutil.copy(file_path, "dataBase/")
                unprocessed_list.insert(tk.END, file_path)
            except Exception as e:
                successful = False
                messagebox.showerror("Error", f"Failed to copy {file_path}: {str(e)}")
                break
        if successful:
            video_count = len(video_files)
            initial_video_count = video_count
            unprocessed_list.delete(0, tk.END)
            unprocessed_list.insert(tk.END, *video_files)
            messagebox.showinfo("Success", "Videos copied successfully to database!")
    else:
        messagebox.showwarning("No Selection", "No videos were selected.")

def load_metadata_file():
    metadata_file = filedialog.askopenfilename(title="Select Metadata File", filetypes=[("CSV files", "*.csv")])
    if metadata_file:
        try:
            shutil.copy(metadata_file, "mos_file.csv")
            messagebox.showinfo("Success", "Metadata file loaded and renamed to mos_file.csv")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load metadata file: {str(e)}")

def set_output_folder():
    folder_path = filedialog.askdirectory(title="Select Output Folder")
    if folder_path:
        try:
            output_files = os.listdir("output/")
            for file_name in output_files:
                shutil.copy(os.path.join("output", file_name), folder_path)
            messagebox.showinfo("Success", "Output files copied successfully!")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to copy output files: {str(e)}")
    else:
        messagebox.showwarning("No Selection", "No output folder was selected.")


def threaded_execute_program():
    # Update the label to show loading message
    countdown_label.config(text="Loading...")
    # Start the execution in a new thread to keep the UI responsive
    thread = threading.Thread(target=execute_program)
    thread.daemon=True
    thread.start()

def execute_program():
    global last_processing_time, video_count, video_files, process, terminate
    start_monitoring()
    while video_files and not terminate:
        video_path = video_files.pop(0)  # Process the first video in the list
        process = subprocess.Popen(["srcCuda.exe", video_path], stdout=subprocess.PIPE, text=True)
        for line in process.stdout:
            print(line, end='')
            match = re.search(r"The code was executed in: (\d+\.\d+) seconds", line)
            if match:
                execution_time = float(match.group(1))
                last_processing_time = execution_time
                video_count -= 1
                display_text = f"{os.path.basename(video_path)} - {execution_time} seconds"
                app.after(0, lambda text=display_text: processed_list.insert(tk.END, text))  # Bind the display text
                app.after(0, lambda: unprocessed_list.delete(0))
                app.after(0, update_countdown)
    terminate = False
    stop_monitoring()


def kill_all_exec_instances(exec_name):
    for proc in psutil.process_iter(['pid', 'name']):
        # Check if process name matches the executable you want to kill
        if proc.info['name'] == exec_name:
            try:
                print(f"Attempting to kill {exec_name} with PID {proc.pid}")
                proc.kill()
                proc.wait()
                print(f"Successfully killed {exec_name} with PID {proc.pid}")
            except psutil.NoSuchProcess:
                print(f"No such process: {exec_name} with PID {proc.pid}")
            except Exception as e:
                print(f"Error killing {exec_name} with PID {proc.pid}: {e}")


def ensure_process_killed(exec_name):
    while any(proc.info['name'] == exec_name for proc in psutil.process_iter(['name'])):
        kill_all_exec_instances(exec_name)
        time.sleep(1)  # Pause to avoid too aggressive CPU usage
        print(f"Re-checking for {exec_name} processes and attempting kill again if found.")


def reset_ui_and_state():
    global video_count, video_files, last_processing_time
    last_processing_time = float('inf')
    progress_var.set(0)  # Reset progress bar
    countdown_label.config(text="Execution cancelled.")
    cpu_label.config(text="CPU Usage: 0%")
    gpu_label.config(text="GPU Usage: 0%")
    ram_label.config(text="RAM Usage: 0%")


def stop_program():
    global process, terminate
    if process:
        try:
            terminate = True
            process.terminate()  # Try polite termination first
            process.wait(timeout=5)  # Wait for the process to terminate
        except (psutil.NoSuchProcess, psutil.TimeoutExpired):
            pass  # If the process does not exist or does not terminate, ignore it
        except Exception as e:
            messagebox.showerror("Error", f"Failed to terminate the process: {e}")
        finally:
            kill_all_exec_instances("srcCuda.exe")  # Kill all instances regardless
            process = None
    stop_monitoring()  # Make sure to stop monitoring resources
    reset_ui_and_state()  # Reset UI and state
    countdown_label.config(text="Program stopped.")  # Update UI


app = tk.Tk()
app.title("Performance Monitor and Program Executor")
app.geometry('800x1000')
app.resizable(True, True)

# Styling
style = ttk.Style()
style.theme_use('clam')
style.configure('TFrame', background='#333333')
style.configure('TLabel', font=('Helvetica', 12), background='#333333', foreground='white')
style.configure('TButton', font=('Helvetica', 12), padding=10)
style.configure("Horizontal.TProgressbar", thickness=30, background='#5FBA7D', troughcolor='#333333')

# Configuring button colors
style.configure('Start.TButton', background='#32CD32', foreground='white')
style.configure('Stop.TButton', background='#FF6347', foreground='white')
style.map('Start.TButton', background=[('active', '#28B463')])
style.map('Stop.TButton', background=[('active', '#FF4500')])

# Create frames for layout
top_frame = ttk.Frame(app, style='TFrame')
top_frame.pack(fill='x', expand=False)

middle_frame = ttk.Frame(app, style='TFrame')
middle_frame.pack(fill='x', expand=False)

bottom_frame = ttk.Frame(app, style='TFrame')
bottom_frame.pack(fill='both', expand=True)

# Progress bar
progress_var = tk.DoubleVar()
progress_bar = ttk.Progressbar(top_frame, orient="horizontal", length=600, mode="determinate", variable=progress_var)
progress_bar.pack(pady=(20, 20), padx=50)

# Button frame for loading and settings
button_frame = ttk.Frame(middle_frame, style='TFrame')
button_frame.pack(pady=(0, 10), fill='x', padx=50)

# Load videos and other settings buttons
load_videos_button = ttk.Button(button_frame, text="Load Videos", command=load_database_videos)
load_videos_button.pack(side='left', expand=True, fill='x', padx=5)

load_metadata_button = ttk.Button(button_frame, text="Load Metadata", command=load_metadata_file)
load_metadata_button.pack(side='left', expand=True, fill='x', padx=5)

set_output_button = ttk.Button(button_frame, text="Set Output Folder", command=set_output_folder)
set_output_button.pack(side='left', expand=True, fill='x', padx=5)

# Start and Stop buttons frame
control_frame = ttk.Frame(middle_frame, style='TFrame')
control_frame.pack(pady=(10, 0), fill='x', padx=50)

start_button = ttk.Button(control_frame, text="Start Program", command=threaded_execute_program, style='Start.TButton')
start_button.pack(side='left', fill='x', expand=True, padx=5)

stop_button = ttk.Button(control_frame, text="Stop Program", command=stop_program, style='Stop.TButton')
stop_button.pack(side='left', fill='x', expand=True, padx=5)



listbox_frame = ttk.Frame(bottom_frame, padding=(20, 10), style='TFrame')
listbox_frame.pack(fill='both', expand=True)

unprocessed_label = ttk.Label(listbox_frame, text="Unprocessed Videos")
unprocessed_label.pack(fill='x')

unprocessed_list = tk.Listbox(listbox_frame, height=10, bg="#222222", fg="white")
unprocessed_list.pack(pady=(10, 20), fill='x', padx=50)

processed_label = ttk.Label(listbox_frame, text="Processed Videos")
processed_label.pack(fill='x')

processed_list = tk.Listbox(listbox_frame, height=10, bg="#222222", fg="white")
processed_list.pack(pady=(0, 10), fill='x', padx=50)

# Move resource monitoring closer to the middle frame
resource_frame = ttk.Frame(middle_frame, style='TFrame')  # Changed from bottom_frame to middle_frame
resource_frame.pack(pady=(20, 10), fill='x', padx=50)

cpu_label = ttk.Label(resource_frame, text="CPU Usage: 0%")
cpu_label.pack(side='left', expand=True, fill='x')

gpu_label = ttk.Label(resource_frame, text="GPU Usage: 0%")
gpu_label.pack(side='left', expand=True, fill='x')

ram_label = ttk.Label(resource_frame, text="RAM Usage: 0%")
ram_label.pack(side='left', expand=True, fill='x')

countdown_label = ttk.Label(top_frame, text="Estimated time remaining: 0 seconds")
countdown_label.pack(pady=(0, 20), fill='x', padx=50)


app.mainloop()