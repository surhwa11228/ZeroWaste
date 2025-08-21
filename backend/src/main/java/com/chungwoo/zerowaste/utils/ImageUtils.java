package com.chungwoo.zerowaste.utils;

import org.springframework.web.multipart.MultipartFile;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;


public class ImageUtils {

    public static byte[] convertToJPG(MultipartFile image) throws IOException {
        BufferedImage inputImage = ImageIO.read(image.getInputStream());

        BufferedImage rgbImage = new BufferedImage(
                inputImage.getWidth(), inputImage.getHeight(), BufferedImage.TYPE_INT_RGB
        );
        Graphics2D g = rgbImage.createGraphics();
        g.drawImage(inputImage, 0, 0, Color.WHITE, null);
        g.dispose();

        ByteArrayOutputStream os = new ByteArrayOutputStream();
        ImageIO.write(rgbImage, "jpg", os);
        return os.toByteArray();
    }
}
