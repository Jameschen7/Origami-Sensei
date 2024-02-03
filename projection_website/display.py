import time
import threading
from flask import Flask
from flask import render_template, Response, stream_with_context
from flask import request
from termcolor import colored

import numpy as np

from configs import ori_model_name2config

app = Flask(__name__)

## Global constants
EMPTY_RESPONSE = "Variable updated", 200 # 204 for no content
debug_message = lambda x: app.logger.debug(colored("-- "+str(x), "red"))
lock = threading.Lock() # ensure that updates are thread-safe
homography = np.array([[ 4.04417623e-01, -1.00672980e-16, -9.70602294e+01],
       [-4.17131426e-17,  4.44550669e-01, -5.73470363e+01],
       [-2.35018606e-18, -9.56022945e-04,  1.00000000e+00]]) # iPad 480x640 reso px to table mm with origin at middle of osmo
GLOBAL_VARS = {
    # "width":4096,                     # try to set a fixed projection website width 
    # "height":2304,                    # try to set a fixed projection website height 
    "coord_unit":"px",                # unit used for x/y_coord in CSS

    ## initial parameters for projector at 70cm high?
    "proj_half_width_mm": 280,        # width of half of the projected website in mm
    "table_mm_2_proj_px_scale":2.43,  # unit conversion from table mm to proj website px

    # ## new parameters for projector at ~75cm high
    # "proj_half_width_mm": 280,        # width of half of the projected website in mm
    # "table_mm_2_proj_px_scale":2.3,  # unit conversion from table mm to proj website px: 345/150
}

## Global var
new_param_flag = False  # update when new params are received
current_ori_model = "dog"
# current_ori_model = "cat"
ori_model_config = ori_model_name2config[current_ori_model]

## display-related variables from the app
display_vars = {
    "stage":1,

    ## initial parameters
    # "x_coord":500,
    # "y_coord":100,
    # "scale":0.71, # this scale number is to used to scale the instruction image to match the proj web px of a 15cm paper 

    # temp parameters for recording videos (also need to comment out conversion from cam to table)
    "x_coord":-110,  # in table mm
    "y_coord":40, # in table mm
    # "scale":0.71 *1.3* 212.13 * GLOBAL_VARS["table_mm_2_proj_px_scale"] / ori_model_config["instruction_image_size"][1][0],
    "scale":0.71 *1.35* 212.13 * GLOBAL_VARS["table_mm_2_proj_px_scale"] / ori_model_config["instruction_image_size"][1][0],

    # ## new parameters
    # "x_coord":-110 * GLOBAL_VARS["table_mm_2_proj_px_scale"],  # in table mm
    # "y_coord":40 * GLOBAL_VARS["table_mm_2_proj_px_scale"], # in table mm
    # "scale":np.sqrt(2)*150 * GLOBAL_VARS["table_mm_2_proj_px_scale"] / ori_model_config["instruction_image_size"][1][0],

    "valid_stage":1, # stage excluding 0 (most recent non-zero stage)
}
display_vars_type = {
    "stage":int,
    "scale":float,
    "x_coord":float,
    "y_coord":float,
    "valid_stage":int,
}


## backend
@app.route("/")
def main():
    table_mm_2_proj_web_px()
    return render_template('main.html.jinja', **display_vars, **GLOBAL_VARS, **ori_model_config)
#     return (\
# f"""
# <!doctype html>
# <html lang=en>
# <head>
#     <meta charset=utf-8>
#     <!-- set the width of the page for responsive design -->
#     <meta name="viewport" content="width=device-width, initial-scale=1">
#     <title>Origami Sensei Projection Website</title>
# </head>

# <body>
#     <p>Current Stats: stage={stage}, scale={scale}, x_coord={x_coord}, y_coord={y_coord} </p>
# </body>
# """)


# @app.route("/scale/<new_scale>")
# def set_scale(new_scale):
#     display_vars["scale"] = float(new_scale)
#     # if DEBUG: print("New scale:", display_vars["scale"])
#     debug_message(f"New scale: {display_vars['scale']}")
#     return EMPTY_RESPONSE

# @app.route("/x_coord/<new_x_coord>")
# def set_x_coord(new_x_coord):
#     display_vars["x_coord"] = float(new_x_coord)
#     # if DEBUG: print("New x_coord:", display_vars["x_coord"])
#     debug_message(f"New x_coord: {display_vars['x_coord']}")
#     return EMPTY_RESPONSE

# @app.route("/y_coord/<new_y_coord>")
# def set_y_coord(new_y_coord):
#     display_vars["y_coord"] = float(new_y_coord)
#     # if DEBUG: print("New y_coord:", display_vars["y_coord"])
#     debug_message(f"New y_coord: {display_vars['y_coord']}")
#     return EMPTY_RESPONSE

@app.route("/param") # ?stage=2
def set_param():
    global new_param_flag
    with lock:
        # update display_vars
        debug_message(request.args)
        new_param_flag = True
        for key, val in request.args.items():
            if key in display_vars:
                display_vars[key] = display_vars_type[key](val)
            else:
                debug_message(f"Invalid parameter received: {key}")
        if display_vars["stage"] != 0:
            display_vars["valid_stage"] = display_vars["stage"]

        # Convert x/y_coord in display_vars from cam px to table mm to proj web px
        if "x_coord" in request.args and "y_coord" in request.args: # and display_vars["stage"]!=0
            coordinate_transform()
    return EMPTY_RESPONSE

@app.route('/param/stream')
def stream():
    """
    URL for web client to listen to Server-Sent Events (SSE)
    """
    def event_stream():
        global new_param_flag
        if request.headers.get('accept') == 'text/event-stream':
            while True:
                # data sending logic here
                time.sleep(0.3) # check every 0.3 seconds, set empirically
                with lock:  # acquire lock so that no update happens while sending current data
                    if new_param_flag:
                        new_param_flag = False # so that the same param won't be updated again
                        message = "" # css style
                        for key, val in display_vars.items():
                            message += f"{key}:{val};"
                        message = message[:-1]
                        debug_message(f"Server-Sent Events (SSE) sent: {message}")
                        yield f"data: {message}\n\n" # stream data format
        else:
            print("!! event-stream is not supported.")

    # use `stream_with_context` to maintain the Flask request context for the duration of a streaming response
    return Response(stream_with_context(event_stream()), content_type='text/event-stream') 

@app.after_request
def add_header(response):
    """
    Add headers to both force latest IE rendering engine or Chrome Frame,
    and also to cache the rendered page for 10 minutes.
    Source: https://stackoverflow.com/questions/34066804/disabling-caching-in-flask
    """
    response.headers["Cache-Control"] = "public, max-age=0, no-cache, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
    # response.headers['Cache-Control'] = 'public, max-age=0'
    return response



########## Geomotry-based backend coordinate conversion & re-localization
def coordinate_transform():
    """
    Convert the current x/y_coord in ipad cam px space to px space

    Overall steps:
        1. homography transformation to the table mm space (origin at the middle of osmo base)
        2. use `proj_half_width_mm` to get the total width from the left boundary of the 
            projected website
        3. use `table_mm_2_proj_px_scale` to convert to proj website px space
        4. adjust the top-left position of the image based on:
            a. scaling around the image center: this causes the upper left corner to move towards 
               the center, so need to subtract some from x/y_coord
            b. we want to image itself to match excluding the arrows, so need to leave space for
               extra size due to the arrows:  

    """
    # update scale
    # display_vars["scale"] *= 212.13 * GLOBAL_VARS["table_mm_2_proj_px_scale"] / ori_model_config["instruction_image_size"][1][0]

    # homography transformation to table mm space
    # iPad_px_2_table_mm()

    # coordinate transformation to proj web px space
    table_mm_2_proj_web_px()

def iPad_px_2_table_mm():
    x = display_vars["x_coord"]
    y = display_vars["y_coord"]
    debug_message(f"Received x,y: {x}, {y}")
    homo_coord = np.array([x, y, 1], dtype=np.float32)
    table_mm_coord = homography @ homo_coord
    table_mm_coord = table_mm_coord[:2] / table_mm_coord[2]
    display_vars["x_coord"] = table_mm_coord[0]
    display_vars["y_coord"] = table_mm_coord[1]
    debug_message(f"Homography fixed x,y: {table_mm_coord}")

def table_mm_2_proj_web_px():
    curr_stage = display_vars["stage"] if display_vars["stage"] else display_vars["valid_stage"]
    current_step_size = ori_model_config["instruction_image_size"][ curr_stage ]
    current_step_offset = ori_model_config["instruction_image_arrow_offset"][ curr_stage ]
    display_vars["x_coord"] = (display_vars["x_coord"] + GLOBAL_VARS["proj_half_width_mm"]) * GLOBAL_VARS["table_mm_2_proj_px_scale"]
    display_vars["y_coord"] = display_vars["y_coord"] * GLOBAL_VARS["table_mm_2_proj_px_scale"]
    debug_message(f'Final x,y in proj web px space: {display_vars["x_coord"]}, {display_vars["y_coord"]}')
    display_vars["x_coord"] += -(1-display_vars["scale"])/2 * current_step_size[0] + current_step_offset[0]*display_vars["scale"]
    display_vars["y_coord"] += -(1-display_vars["scale"])/2 * current_step_size[1] + current_step_offset[1]*display_vars["scale"]
    # display_vars["x_coord"] += -(1-display_vars["scale"])/2 * current_step_size[0]
    # display_vars["y_coord"] += -(1-display_vars["scale"])/2 * current_step_size[1]

    debug_message(f'Final x,y in proj web px space: {display_vars["x_coord"]}, {display_vars["y_coord"]}')
