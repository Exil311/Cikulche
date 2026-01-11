package com.cikulche.domain.user.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;

@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User implements UserDetails { // <--- ТОВА Е КЛЮЧЪТ! Трябва да имплементира UserDetails

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String passwordHash;

    @Column(name = "full_name")
    private String name;

    private Integer birthYear;

    @Builder.Default
    @Column(columnDefinition = "integer default 28")
    private Integer averageCycleLength = 28;

    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    // --- SECURITY МЕТОДИ (Задължителни са, за да спре грешката) ---

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        // Връщаме роля "USER" по подразбиране
        return List.of(new SimpleGrantedAuthority("USER"));
    }

    @Override
    public String getPassword() {
        return passwordHash; // Казваме на Spring, че това ни е паролата
    }

    @Override
    public String getUsername() {
        return email; // Казваме на Spring, че това ни е потребителското име
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return true;
    }
}