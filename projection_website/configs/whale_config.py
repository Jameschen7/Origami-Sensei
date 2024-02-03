whale_config = {
    ## path to whale instructions
    # "instruction_image_folder": "",
    # "name": "whale",
    "instruction_img_path_prefix": "static/instructions/whale/instructions_scaled/whale_instruction_Inst", # static/instructions/dog/instructions_scaled/dog_instruction_Inst1.png
    "instruction_gif_path_prefix": "static/instructions/whale/gifs/inst_small", # static/instructions/dog/gifs/inst_small4.gif
    "final_step_image_path":"static/instructions/whale/finished.png",

    ## fixed parameters related to dog instructions
    "total_step_num": 6,
    "instruction_image_size":{ # for top-left corner position adjustment
        1: (1146,1146),
        2: (1146,1146),
        3: (1146,676),
        4: (979,676),
        5: (986,420),
        6: (742,373),
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
    #     2: (0,0),
    #     3: (0,260),
    #     4: (150,260),
    #     5: (150,260-77),
    #     6: (150,260),
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