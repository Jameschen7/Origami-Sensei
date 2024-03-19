dog_config = {
    ## path to dog instructions
    # "instruction_image_folder": "",
    # "name": "dog",
    "instruction_img_path_prefix": "static/instructions/dog/instructions_scaled/dog_instruction_Inst", # static/instructions/dog/instructions_scaled/instruction_Inst1.png
    "instruction_gif_path_prefix": "static/instructions/dog/gifs/inst_small", # static/instructions/dog/gifs/inst_small4.gif
    "final_step_image_path":"static/instructions/dog/finished.png",

    ## fixed parameters related to dog instructions
    "total_step_num": 8,
    "instruction_image_size":{ # for top-left corner position adjustment
        1: (687,687),
        2: (693,347),
        3: (693,431),
        4: (703,396),
        5: (238,269),
        6: (568,319),
        7: (323,320),
        8: (250,321)
    },
    "instruction_image_arrow_offset":{ # for top-left corner position adjustment
        1: (0,0),
        2: (0,0),
        3: (0,0),
        4: (-8,-167),
        5: (-2,-41),
        6: (0,0),
        7: (-36,0),
        8: (0,0)
    },
    "instruction_texts":{
        1: "Fold the upper corner diagonally down to the bottom corner.",
        2: "Fold one flap of the paper up along the dashed line.",
        3: "Fold the other flap of the paper backwards along the dash-dot line.",
        4: "Fold both edges diagonally towards the middle. The creases should start from bottom corners.",
        5: "Fold both edges outwards along the dashed line so that the hypotenuse overlaps with the vertical leg.",
        6: "Flip the paper over.",
        7: "Fold the top corner of the head backwards along the dash-dot line to reveal the ear.",
        8: "Task completed!!  Congratulations!!"
    },

    # "instruction_image_arrow_offset":{ # temporary for video recording
    #     1: (0,0),
    #     2: (0,340),
    #     3: (0,340),
    #     4: (-10,180),
    #     5: (210,300),
    #     6: (210,250),
    #     7: (180,250),
    #     8: (200,250),
    # },
}