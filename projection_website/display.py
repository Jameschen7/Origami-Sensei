import time
import threading
from flask import Flask
from flask import render_template, Response, stream_with_context
from flask import request
from termcolor import colored

app = Flask(__name__)

## Global var
EMPTY_RESPONSE = "Variable updated", 200 # 204 for no content
debug_message = lambda x: app.logger.debug(colored("-- "+str(x), "red"))
# DEBUG = True
NEW_PARAM_FLAG = False # update when new params are received
lock = threading.Lock()

## display-related variables from the app
GLOBAL_VARS = {
    "width":4096,
    "height":2304,
}
display_vars = {
    "stage":1,
    "scale":0.67,
    "x_coord":20,
    "y_coord":10,
}
display_vars_type = {
    "stage":int,
    "scale":float,
    "x_coord":float,
    "y_coord":float,
}


## backend
@app.route("/")
def main():
    return render_template('main.html.jinja', **display_vars, **GLOBAL_VARS)
    # return render_template('main.html.jinja', stage=stage, scale=scale, x_coord=x_coord, y_coord=y_coord)
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

@app.route("/scale/<new_scale>")
def set_scale(new_scale):
    display_vars["scale"] = float(new_scale)
    # if DEBUG: print("New scale:", display_vars["scale"])
    debug_message(f"New scale: {display_vars['scale']}")
    return EMPTY_RESPONSE

@app.route("/x_coord/<new_x_coord>")
def set_x_coord(new_x_coord):
    display_vars["x_coord"] = float(new_x_coord)
    # if DEBUG: print("New x_coord:", display_vars["x_coord"])
    debug_message(f"New x_coord: {display_vars['x_coord']}")
    return EMPTY_RESPONSE

@app.route("/y_coord/<new_y_coord>")
def set_y_coord(new_y_coord):
    display_vars["y_coord"] = float(new_y_coord)
    # if DEBUG: print("New y_coord:", display_vars["y_coord"])
    debug_message(f"New y_coord: {display_vars['y_coord']}")
    return EMPTY_RESPONSE

@app.route("/param")
def set_param():
    global NEW_PARAM_FLAG
    for key, val in request.args.items():
        if key in display_vars:
            display_vars[key] = display_vars_type[key](val)
        else:
            debug_message(f"Invalid parameter received: {key}")
    # if DEBUG: print(request.args)
    debug_message(request.args)
    with lock:
        NEW_PARAM_FLAG = True
    return EMPTY_RESPONSE

@app.route('/param/stream')
def stream():
    def event_stream():
        global NEW_PARAM_FLAG
        if request.headers.get('accept') == 'text/event-stream':
            while True:
                # data sending logic here
                time.sleep(0.5) # check every 0.5 seconds
                with lock:
                    if NEW_PARAM_FLAG:
                        NEW_PARAM_FLAG = False
                        message = "" # css style
                        for key, val in display_vars.items():
                            message += f"{key}:{val};"
                        message = message[:-1]
                        debug_message(f"Server-Sent Events (SSE) sent: {message}")
                        yield f"data: {message}\n\n" # stream data format
        else:
            print("!! event-stream is not supported.")

    return Response(stream_with_context(event_stream()), content_type='text/event-stream') # maintain the Flask request context for the duration of a streaming response

@app.after_request
def add_header(response):
    """
    Add headers to both force latest IE rendering engine or Chrome Frame,
    and also to cache the rendered page for 10 minutes.
    Source: https://stackoverflow.com/questions/34066804/disabling-caching-in-flask
    """
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
    response.headers['Cache-Control'] = 'public, max-age=0'
    return response