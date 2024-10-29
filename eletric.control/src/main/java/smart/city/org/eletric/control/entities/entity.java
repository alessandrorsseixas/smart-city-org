package smart.city.org.eletric.control.entities;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import org.springframework.data.annotation.Id;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.util.Date;

@Data
public abstract class entity {
    @Id
    private String id;

    @NotNull
    private String createdAt;

    @NotNull
    private String createdUtcAt;

    @NotBlank
    private String createdBy;

    private String updatedUtcAt;

    private String updatedAt;

    private String updatedBy;


}
