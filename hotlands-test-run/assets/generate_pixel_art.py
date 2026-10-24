from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parent
SPRITES = ROOT / "sprites"
ENVIRONMENT = ROOT / "environment"
SPRITES.mkdir(parents=True, exist_ok=True)
ENVIRONMENT.mkdir(parents=True, exist_ok=True)


def save(image: Image.Image, path: Path) -> None:
    image.save(path)
    print(path)


def make_player_frame(pose: str = "idle", phase: int = 0) -> Image.Image:
    """Draw one hard-edged, one-colour 64 x 64 character animation frame."""
    image = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    # The player remains pure white in every frame; it is the only white sprite.
    color = (255, 255, 255, 255)
    bob = 1 if pose == "idle" and phase in (1, 3) else 0

    # Head and torso stay simple so the silhouette remains readable at game scale.
    draw.rectangle((26, 10 + bob, 37, 21 + bob), fill=color)
    draw.rectangle((24, 23 + bob, 39, 40 + bob), fill=color)

    if pose == "walk":
        # Six distinct strides: arms counter-swing while the feet alternate.
        arm_shift = (-3, -1, 2, 3, 1, -2)[phase % 6]
        leg_shift = (-4, -2, 2, 4, 2, -2)[phase % 6]
        draw.rectangle((20, 25 + arm_shift, 23, 37 + arm_shift), fill=color)
        draw.rectangle((40, 25 - arm_shift, 43, 37 - arm_shift), fill=color)
        draw.rectangle((25, 40, 30 + leg_shift, 49), fill=color)
        draw.rectangle((34 - leg_shift, 40, 39, 49), fill=color)
        draw.rectangle((22 + min(0, leg_shift), 50, 30 + leg_shift, 53), fill=color)
        draw.rectangle((34 - leg_shift, 50, 42 + max(0, -leg_shift), 53), fill=color)
    elif pose == "jump":
        # Arms raised and legs tucked make airborne state distinct in either gravity direction.
        draw.polygon(((24, 28), (20, 24), (16, 17), (19, 14), (26, 22), (27, 28)), fill=color)
        draw.polygon(((39, 28), (43, 24), (47, 17), (44, 14), (37, 22), (36, 28)), fill=color)
        if phase % 2 == 0:
            draw.polygon(((25, 39), (31, 39), (30, 48), (25, 50), (21, 47)), fill=color)
            draw.polygon(((33, 39), (39, 39), (43, 47), (39, 50), (34, 48)), fill=color)
        else:
            draw.polygon(((25, 39), (31, 39), (33, 48), (29, 51), (23, 48)), fill=color)
            draw.polygon(((33, 39), (39, 39), (40, 48), (35, 51), (31, 48)), fill=color)
    else:
        draw.rectangle((20, 26 + bob, 23, 38 + bob), fill=color)
        draw.rectangle((40, 26 + bob, 43, 38 + bob), fill=color)
        draw.rectangle((24, 40 + bob, 31, 50 + bob), fill=color)
        draw.rectangle((32, 40 + bob, 39, 50 + bob), fill=color)
        draw.rectangle((21, 51 + bob, 31, 53 + bob), fill=color)
        draw.rectangle((32, 51 + bob, 42, 53 + bob), fill=color)
    return image


def make_player_sheet() -> Image.Image:
    # Rows are idle (4 frames), walk (6 frames), and jump (2 frames).
    sheet = Image.new("RGBA", (64 * 6, 64 * 3), (0, 0, 0, 0))
    for row, (pose, count) in enumerate((("idle", 4), ("walk", 6), ("jump", 2))):
        for phase in range(count):
            sheet.paste(make_player_frame(pose, phase), (phase * 64, row * 64))
    return sheet


def make_box(primary: tuple[int, int, int], bright: tuple[int, int, int]) -> Image.Image:
    black = (0, 0, 0, 255)
    primary_rgba = primary + (255,)
    bright_rgba = bright + (255,)
    crimson = (255, 0, 51, 255)
    purple = (138, 43, 226, 255)
    yellow = (255, 255, 0, 255)
    image = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rectangle((4, 4, 59, 59), fill=black)
    draw.rectangle((8, 8, 55, 55), fill=primary_rgba)
    draw.rectangle((12, 12, 51, 15), fill=bright_rgba)
    draw.rectangle((12, 16, 15, 45), fill=bright_rgba)
    draw.rectangle((48, 16, 51, 45), fill=black)
    # A staring eye replaces the old abstract glyph; pixel veins spread from its socket.
    draw.polygon(((8, 26), (16, 29), (22, 25), (26, 29), (17, 34), (8, 32)), fill=crimson)
    draw.polygon(((56, 26), (48, 29), (42, 25), (38, 29), (47, 34), (56, 32)), fill=purple)
    draw.ellipse((19, 17, 44, 43), fill=black)
    draw.ellipse((22, 20, 41, 40), fill=bright_rgba)
    draw.ellipse((27, 22, 37, 38), fill=yellow)
    draw.ellipse((30, 24, 36, 36), fill=black)
    draw.rectangle((31, 25, 32, 27), fill=yellow)
    # Fanged lower seam and short organic tendrils stay inside the 64 px collision art.
    draw.rectangle((18, 45, 45, 50), fill=black)
    for x in (21, 28, 35, 42):
        draw.polygon(((x, 45), (x + 4, 45), (x + 2, 50)), fill=yellow)
    draw.line(((17, 51), (13, 55), (16, 58)), fill=crimson, width=3)
    draw.line(((47, 51), (51, 55), (48, 58)), fill=purple, width=3)
    draw.rectangle((8, 8, 11, 11), fill=yellow)
    draw.rectangle((52, 8, 55, 11), fill=crimson)
    return image


def make_concrete() -> Image.Image:
    image = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    black = (0, 0, 0, 255)
    purple = (138, 43, 226, 255)
    crimson = (255, 0, 51, 255)
    yellow = (255, 255, 0, 255)
    lime = (0, 255, 51, 255)
    draw.rectangle((3, 3, 60, 60), fill=black)
    draw.rectangle((8, 7, 55, 56), fill=purple)
    draw.rectangle((12, 11, 51, 52), fill=black)
    draw.rectangle((12, 11, 51, 15), fill=crimson)
    draw.rectangle((12, 16, 15, 47), fill=purple)
    draw.rectangle((48, 16, 51, 47), fill=crimson)
    # Cross-hatched fissures and an embedded eye make the pillar feel alive.
    for offset in range(0, 30, 6):
        draw.line((16 + offset, 17, 23 + offset, 24), fill=purple, width=2)
        draw.line((17, 20 + offset, 24, 27 + offset), fill=crimson, width=2)
    draw.ellipse((20, 21, 43, 42), fill=purple)
    draw.ellipse((24, 24, 39, 39), fill=yellow)
    draw.ellipse((29, 25, 35, 38), fill=black)
    draw.rectangle((30, 27, 32, 29), fill=lime)
    draw.line(((13, 50), (8, 54), (13, 58)), fill=crimson, width=3)
    draw.line(((51, 49), (56, 54), (51, 59)), fill=lime, width=3)
    return image


def make_rail_tile() -> Image.Image:
    image = Image.new("RGBA", (64, 64), (0, 0, 0, 255))
    draw = ImageDraw.Draw(image)
    purple = (138, 43, 226, 255)
    lime = (0, 255, 51, 255)
    yellow = (255, 255, 0, 255)
    crimson = (255, 0, 51, 255)
    draw.rectangle((0, 0, 63, 5), fill=purple)
    draw.rectangle((0, 58, 63, 63), fill=purple)
    draw.rectangle((0, 25, 63, 38), fill=lime)
    draw.rectangle((0, 28, 63, 35), fill=crimson)
    draw.rectangle((0, 30, 63, 32), fill=yellow)
    for x in (7, 23, 39, 55):
        draw.rectangle((x, 19, x + 3, 44), fill=(0, 0, 0, 255))
        draw.rectangle((x + 1, 21, x + 2, 42), fill=purple)
    draw.ellipse((26, 7, 37, 18), fill=yellow)
    draw.ellipse((30, 9, 34, 17), fill=(0, 0, 0, 255))
    draw.rectangle((28, 46, 35, 56), fill=crimson)
    return image


def make_platform_tile() -> Image.Image:
    image = Image.new("RGBA", (64, 64), (0, 0, 0, 255))
    draw = ImageDraw.Draw(image)
    white = (255, 255, 255, 255)
    draw.rectangle((0, 0, 63, 7), fill=white)
    draw.rectangle((4, 16, 59, 59), fill=white)
    draw.rectangle((8, 20, 55, 55), fill=(0, 0, 0, 255))
    # Cross-hatching reads as retro stone/organic tissue after the level tint is applied.
    for x in range(10, 56, 8):
        draw.line((x, 22, x + 12, 34), fill=white, width=2)
        draw.line((x, 42, x + 10, 52), fill=white, width=1)
    draw.rectangle((44, 40, 51, 47), fill=white)
    draw.rectangle((46, 42, 49, 45), fill=(0, 0, 0, 255))
    return image


def make_background() -> Image.Image:
    # One 128 x 128 illustration. The game scales it across the room once rather
    # than tiling it, so keep the silhouette bold and leave plenty of black space.
    image = Image.new("RGB", (128, 128), (0, 0, 0))
    draw = ImageDraw.Draw(image)
    # Lighter, softer tree tones separate the backdrop from saturated gameplay art.
    purple = (137, 166, 207)
    crimson = (173, 111, 145)
    lime = (121, 191, 170)
    yellow = (220, 210, 144)

    # Gnarled central trunk with roots. The restrained purple silhouette keeps
    # the play area dark while still reading clearly behind platforms and sprites.
    draw.polygon(
        ((53, 128), (57, 105), (54, 91), (59, 78), (56, 65), (59, 49),
         (68, 47), (72, 63), (69, 78), (74, 93), (70, 109), (76, 128)),
        fill=purple,
    )
    draw.polygon(((62, 127), (64, 108), (62, 91), (65, 79), (63, 63), (66, 52),
                  (68, 64), (67, 81), (69, 96), (66, 111), (68, 127)), fill=crimson)

    # Long crooked branches frame the room and reach almost to each edge.
    branches = [
        (((63, 70), (50, 64), (43, 56), (31, 54), (23, 45), (9, 43)), purple, 5),
        (((61, 62), (49, 53), (43, 43), (30, 38), (20, 28), (5, 25)), purple, 4),
        (((64, 78), (50, 75), (40, 68), (29, 70), (17, 64), (4, 65)), purple, 4),
        (((67, 69), (80, 63), (88, 53), (101, 49), (111, 40), (126, 37)), purple, 5),
        (((67, 58), (79, 49), (84, 39), (97, 34), (106, 24), (124, 20)), purple, 4),
        (((69, 80), (82, 74), (94, 76), (105, 68), (116, 70), (127, 62)), purple, 4),
    ]
    for points, color, width in branches:
        draw.line(points, fill=color, width=width, joint="curve")
    # A few red bark seams make the tree feel raw without filling the backdrop.
    draw.line(((58, 112), (63, 99), (60, 88), (65, 76), (62, 65)), fill=crimson, width=2)
    draw.line(((49, 62), (38, 57), (31, 47), (18, 45)), fill=crimson, width=1)
    draw.line(((80, 61), (91, 53), (103, 51), (112, 42)), fill=crimson, width=1)
    draw.line(((57, 100), (47, 107), (42, 119), (35, 127)), fill=purple, width=4)
    draw.line(((68, 105), (80, 112), (86, 123), (94, 128)), fill=purple, width=4)

    def eye(cx: int, cy: int, size: int, accent: tuple[int, int, int]) -> None:
        """A tiny unsettling eye embedded in the bark."""
        half_w = size
        half_h = max(2, size - 1)
        draw.polygon(((cx - half_w - 2, cy), (cx - half_w, cy - half_h),
                      (cx, cy - half_h - 1), (cx + half_w, cy - half_h),
                      (cx + half_w + 2, cy), (cx + half_w, cy + half_h),
                      (cx, cy + half_h + 1), (cx - half_w, cy + half_h)), fill=crimson)
        draw.ellipse((cx - half_w, cy - half_h, cx + half_w, cy + half_h), fill=yellow)
        draw.rectangle((cx - 1, cy - half_h, cx + 1, cy + half_h), fill=(0, 0, 0))
        draw.point((cx, cy - 1), fill=accent)

    # One large eye watches from the trunk; smaller eyes sit along the branches.
    eye(65, 88, 5, lime)
    for cx, cy, accent in ((13, 43, lime), (29, 53, yellow), (18, 29, lime),
                           (115, 41, lime), (99, 52, yellow), (119, 65, lime)):
        eye(cx, cy, 2, accent)

    # Short thorn-like offshoots keep the outline organic and unsettling.
    for points in (
        ((30, 53), (26, 46), (27, 41)), ((44, 57), (40, 50), (41, 46)),
        ((22, 45), (18, 39), (19, 35)), ((99, 50), (103, 43), (102, 39)),
        ((111, 42), (115, 35), (114, 30)), ((95, 75), (100, 81), (99, 86)),
        ((34, 69), (29, 76), (30, 81)),
    ):
        draw.line(points, fill=purple, width=2)
    return image


def make_title_eyes() -> Image.Image:
    """Draw only isolated cosmic eyes on black for the title screen."""
    image = Image.new("RGB", (128, 128), (0, 0, 0))
    draw = ImageDraw.Draw(image)
    purple = (138, 43, 226)
    crimson = (255, 0, 51)
    lime = (0, 255, 51)
    yellow = (255, 255, 0)

    def eye(cx: int, cy: int, rx: int, ry: int, iris: tuple[int, int, int], socket: tuple[int, int, int]) -> None:
        points = ((cx - rx - 3, cy), (cx - rx, cy - ry), (cx - 2, cy - ry - 1),
                  (cx + rx, cy - ry), (cx + rx + 3, cy), (cx + rx, cy + ry),
                  (cx + 2, cy + ry + 1), (cx - rx, cy + ry))
        draw.polygon(points, fill=socket)
        draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=yellow)
        draw.rectangle((cx - 1, cy - ry, cx + 1, cy + ry), fill=iris)
        draw.point((cx - 1, cy - 1), fill=lime if iris == purple else purple)

    # Keep the center open for the title and menu; watchful eyes live around the edges.
    eye(14, 13, 4, 3, purple, crimson)
    eye(43, 9, 3, 2, crimson, purple)
    eye(83, 12, 4, 3, lime, purple)
    eye(114, 15, 5, 3, purple, crimson)
    eye(8, 43, 4, 3, lime, purple)
    eye(22, 77, 3, 2, crimson, purple)
    eye(10, 112, 5, 3, purple, crimson)
    eye(118, 47, 4, 3, crimson, purple)
    eye(104, 82, 4, 2, lime, crimson)
    eye(118, 109, 5, 3, purple, crimson)
    eye(48, 120, 4, 2, crimson, purple)
    eye(79, 119, 3, 2, lime, purple)
    return image


save(make_player_frame(), SPRITES / "player_silhouette_64.png")
save(make_player_sheet(), SPRITES / "player_sheet_64.png")
save(make_box((0, 255, 51), (255, 255, 0)), SPRITES / "box_silver_64.png")
save(make_box((255, 0, 51), (138, 43, 226)), SPRITES / "box_amber_64.png")
save(make_concrete(), SPRITES / "pillar_concrete_64.png")
save(make_rail_tile(), ENVIRONMENT / "rail_tile_64.png")
save(make_platform_tile(), ENVIRONMENT / "platform_tile_64.png")
save(make_background(), ENVIRONMENT / "lab_background.png")
save(make_title_eyes(), ENVIRONMENT / "title_eye_background.png")
