cat_config = {
    ## path to cat instructions
    # "instruction_image_folder": "",
    # "name": "cat",
    "instruction_img_path_prefix": "static/instructions/cat/instructions_scaled/cat_instruction_Inst", # static/instructions/dog/instructions_scaled/dog_instruction_Inst1.png
    "instruction_gif_path_prefix": "static/instructions/cat/gifs/inst_small", # static/instructions/dog/gifs/inst_small4.gif
    "final_step_image_path":"static/instructions/cat/finished.png",

    ## fixed parameters related to dog instructions
    "total_step_num": 9,
    "instruction_image_size":{ # for top-left corner position adjustment
        1: (917,917),
        2: (923,462),
        3: (452,459),
        4: (452,358),
        5: (452,415),
        6: (796,415),
        7: (446,415),
        8: (446,310),
        9: (446,315),
    },
    "instruction_image_arrow_offset":{ # for top-left corner position adjustment
        1: (0,0),
        2: (0,0),
        3: (0,0),
        4: (0,0),
        5: (0,-77),
        6: (0,0),
    },
    # "instruction_image_arrow_offset":{ # temporary for video recording
    #     1: (0,0),
    #     2: (0,460),
    #     3: (220,460),
    #     4: (220,560),
    #     5: (220,500),
    #     6: (220,500),
    #     7: (220,500),
    #     8: (220,500),
    #     9: (220,500),
    # },
    "instruction_texts":{
        1: "Fold the upper corner diagonally down to the bottom corner.",
        2: "Fold one flap of the paper up along the dashed line.",
        3: "Fold both edges outwards along the dashed line so that the hypotenuse overlaps with the vertical leg.",
        4: "Flip the paper over.",
        5: "Fold the top corner of the head backwards along the dash-dot line to reveal the ear.",
        6: "Task completed!!  Congratulations!!"
    }
}